import 'server-only';
import type { User } from '@supabase/supabase-js';
import { adminSupabase } from './supabase';

const dayMs = 86_400_000;

async function allAuthUsers() {
  const service = adminSupabase();
  const users: User[] = [];
  const perPage = 1000;
  for (let page = 1; page <= 10; page += 1) {
    const { data, error } = await service.auth.admin.listUsers({ page, perPage });
    if (error) throw error;
    users.push(...data.users);
    if (data.users.length < perPage) break;
  }
  return users;
}

export async function getDashboardData() {
  const service = adminSupabase();
  const now = Date.now();
  const thirtyDaysAgo = new Date(now - 30 * dayMs).toISOString();
  const trendStart = new Date(now - 13 * dayMs);
  trendStart.setUTCHours(0, 0, 0, 0);

  const [authUsers, profilesResult, petsResult, activitiesResult, entitlementsResult, overridesResult, auditResult] =
    await Promise.all([
      allAuthUsers(),
      service.from('users').select('id, name, created_at'),
      service.from('pets').select('id, user_id, species, created_at'),
      service
        .from('activities')
        .select('user_id, type, points, start_time')
        .gte('start_time', trendStart.toISOString()),
      service.from('account_entitlements').select('user_id, tier, status, source'),
      service
        .from('admin_entitlement_overrides')
        .select('user_id, tier, expires_at, active'),
      service
        .from('admin_audit_log')
        .select('id, action, target_user_id_text, reason, created_at')
        .order('created_at', { ascending: false })
        .limit(12),
    ]);
  for (const result of [profilesResult, petsResult, activitiesResult, entitlementsResult, overridesResult, auditResult]) {
    if (result.error) throw result.error;
  }

  const profiles = profilesResult.data ?? [];
  const pets = petsResult.data ?? [];
  const activities = activitiesResult.data ?? [];
  const entitlements = entitlementsResult.data ?? [];
  const overrides = overridesResult.data ?? [];
  const profileById = new Map(profiles.map((profile) => [profile.id, profile]));
  const entitlementById = new Map(entitlements.map((item) => [item.user_id, item]));
  const overrideById = new Map(
    overrides
      .filter((item) => item.active && (!item.expires_at || Date.parse(item.expires_at) > now))
      .map((item) => [item.user_id, item]),
  );
  const petCounts = new Map<string, number>();
  for (const pet of pets) petCounts.set(pet.user_id, (petCounts.get(pet.user_id) ?? 0) + 1);
  const activityByUser = new Map<string, { logs: number; points: number; last: string }>();
  for (const activity of activities) {
    const current = activityByUser.get(activity.user_id) ?? { logs: 0, points: 0, last: '' };
    current.logs += 1;
    current.points += activity.points ?? 0;
    if (activity.start_time > current.last) current.last = activity.start_time;
    activityByUser.set(activity.user_id, current);
  }

  const users = authUsers.map((user) => {
    const profile = profileById.get(user.id);
    const activity = activityByUser.get(user.id);
    const entitlement = entitlementById.get(user.id);
    const override = overrideById.get(user.id);
    return {
      id: user.id,
      email: user.email ?? 'No email',
      name: profile?.name ?? null,
      createdAt: user.created_at,
      lastSignInAt: user.last_sign_in_at ?? null,
      suspendedUntil: user.banned_until ?? null,
      pets: petCounts.get(user.id) ?? 0,
      careLogs30d: activity?.logs ?? 0,
      pawPoints30d: activity?.points ?? 0,
      lastCareAt: activity?.last || null,
      plan: override?.tier ?? entitlement?.tier ?? 'free',
      planStatus: override ? 'manual override' : entitlement?.status ?? 'none',
    };
  });

  const activeUsers = users.filter((user) => {
    const lastTouch = Math.max(
      user.lastSignInAt ? Date.parse(user.lastSignInAt) : 0,
      user.lastCareAt ? Date.parse(user.lastCareAt) : 0,
    );
    return lastTouch >= Date.parse(thirtyDaysAgo);
  }).length;
  const eligibleForRetention = users.filter((user) => Date.parse(user.createdAt) <= now - 7 * dayMs);
  const retained = eligibleForRetention.filter((user) => {
    const recent = Math.max(
      user.lastSignInAt ? Date.parse(user.lastSignInAt) : 0,
      user.lastCareAt ? Date.parse(user.lastCareAt) : 0,
    );
    return recent >= now - 7 * dayMs;
  }).length;

  const trend = Array.from({ length: 14 }, (_, index) => {
    const date = new Date(trendStart.getTime() + index * dayMs);
    const key = date.toISOString().slice(0, 10);
    const rows = activities.filter((activity) => activity.start_time.slice(0, 10) === key);
    return {
      date: key,
      careLogs: rows.length,
      pawPoints: rows.reduce((sum, row) => sum + (row.points ?? 0), 0),
    };
  });

  const planDistribution = users.reduce<Record<string, number>>((result, user) => {
    const key = `${user.plan} · ${user.planStatus}`;
    result[key] = (result[key] ?? 0) + 1;
    return result;
  }, {});

  return {
    metrics: {
      totalUsers: users.length,
      activeUsers30d: activeUsers,
      pets: pets.length,
      careLogs14d: activities.length,
      pawPoints14d: activities.reduce((sum, item) => sum + (item.points ?? 0), 0),
      retained7dPercent: eligibleForRetention.length
        ? Math.round((retained / eligibleForRetention.length) * 100)
        : 0,
    },
    trend,
    planDistribution,
    users: users.sort((a, b) =>
      (b.lastSignInAt ?? b.createdAt).localeCompare(a.lastSignInAt ?? a.createdAt),
    ),
    recentAudit: auditResult.data ?? [],
  };
}

export async function getUserDetail(userId: string) {
  const service = adminSupabase();
  const [authResult, profileResult, petsResult, activitiesResult, entitlementResult, overrideResult, auditResult] =
    await Promise.all([
      service.auth.admin.getUserById(userId),
      service.from('users').select('id, name, email, created_at').eq('id', userId).maybeSingle(),
      service
        .from('pets')
        .select('id, name, species, breed, created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false }),
      service
        .from('activities')
        .select('id, type, points, start_time, pet_id')
        .eq('user_id', userId)
        .order('start_time', { ascending: false })
        .limit(50),
      service.from('account_entitlements').select('*').eq('user_id', userId).maybeSingle(),
      service
        .from('admin_entitlement_overrides')
        .select('tier, reason, expires_at, active, created_at')
        .eq('user_id', userId)
        .maybeSingle(),
      service
        .from('admin_audit_log')
        .select('id, action, reason, metadata, created_at')
        .eq('target_user_id_text', userId)
        .order('created_at', { ascending: false })
        .limit(20),
    ]);
  if (authResult.error) throw authResult.error;
  return {
    user: {
      id: userId,
      email: authResult.data.user.email ?? profileResult.data?.email ?? 'No email',
      name: profileResult.data?.name ?? null,
      createdAt: authResult.data.user.created_at,
      lastSignInAt: authResult.data.user.last_sign_in_at ?? null,
      suspendedUntil: authResult.data.user.banned_until ?? null,
    },
    pets: petsResult.data ?? [],
    activities: activitiesResult.data ?? [],
    entitlement: entitlementResult.data,
    override: overrideResult.data,
    audit: auditResult.data ?? [],
  };
}
