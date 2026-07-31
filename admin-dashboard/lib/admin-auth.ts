import 'server-only';
import { redirect } from 'next/navigation';
import { adminSupabase, userSupabase } from './supabase';

export type AdminIdentity = {
  userId: string;
  email: string;
  role: 'owner' | 'admin';
};

export async function getAdminIdentity(): Promise<AdminIdentity | null> {
  const userClient = await userSupabase();
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user?.email) return null;

  const service = adminSupabase();
  const { data: admin } = await service
    .from('admin_users')
    .select('role, enabled')
    .eq('user_id', data.user.id)
    .eq('enabled', true)
    .maybeSingle();
  if (!admin || (admin.role !== 'owner' && admin.role !== 'admin')) return null;
  return { userId: data.user.id, email: data.user.email, role: admin.role };
}

export async function requireAdmin(ownerOnly = false) {
  const identity = await getAdminIdentity();
  if (!identity) redirect('/login?error=not-authorized');
  if (ownerOnly && identity.role !== 'owner') redirect('/admin?error=owner-required');
  return identity;
}
