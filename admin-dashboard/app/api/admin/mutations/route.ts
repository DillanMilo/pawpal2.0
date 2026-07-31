import { NextResponse, type NextRequest } from 'next/server';
import { getAdminIdentity } from '@/lib/admin-auth';
import { serverEnv } from '@/lib/env';
import { adminMutationSchema, hasValidDeleteConfirmation, isAllowedMutationOrigin } from '@/lib/mutation-schema';
import { adminSupabase } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

async function auditFailure(actorId: string, targetId: string, reason: string, attemptedAction: string, error: string) {
  await adminSupabase().from('admin_audit_log').insert({
    actor_user_id: actorId, target_user_id: targetId, target_user_id_text: targetId,
    action: 'user.mutation_failed', reason, metadata: { attempted_action: attemptedAction, error },
  });
}

export async function POST(request: NextRequest) {
  const identity = await getAdminIdentity();
  if (!identity) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const env = serverEnv();
  if (request.headers.get('x-pawpal-admin') !== '1' || !isAllowedMutationOrigin(request.headers.get('origin'), env.NEXT_PUBLIC_ADMIN_ORIGIN)) {
    return NextResponse.json({ error: 'Invalid request origin' }, { status: 403 });
  }

  const parsed = adminMutationSchema.safeParse(await request.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid or incomplete confirmation' }, { status: 400 });
  const input = parsed.data;
  if (input.targetUserId === identity.userId && ['suspend_user', 'delete_user'].includes(input.action)) {
    return NextResponse.json({ error: 'You cannot suspend or delete your own admin account' }, { status: 400 });
  }
  const service = adminSupabase();

  try {
    if (input.action === 'grant_override') {
      const expiresAt = input.expiresAt ? new Date(input.expiresAt).toISOString() : null;
      const { error } = await service.rpc('admin_apply_entitlement_override', {
        p_actor_user_id: identity.userId, p_target_user_id: input.targetUserId,
        p_tier: input.tier, p_reason: input.reason, p_expires_at: expiresAt,
      });
      if (error) throw error;
    } else if (input.action === 'revoke_override') {
      const { error } = await service.rpc('admin_revoke_entitlement_override', {
        p_actor_user_id: identity.userId, p_target_user_id: input.targetUserId, p_reason: input.reason,
      });
      if (error) throw error;
    } else {
      const { data: target, error: targetError } = await service.auth.admin.getUserById(input.targetUserId);
      if (targetError || !target.user.email) throw targetError ?? new Error('Target user not found');
      if (input.action === 'delete_user') {
        if (identity.role !== 'owner') return NextResponse.json({ error: 'Owner role required for permanent deletion' }, { status: 403 });
        if (!hasValidDeleteConfirmation(input.confirmation, target.user.email)) return NextResponse.json({ error: 'Typed email confirmation does not match' }, { status: 400 });
        const { data: audit, error: auditError } = await service.from('admin_audit_log').insert({ actor_user_id: identity.userId, target_user_id: input.targetUserId, target_user_id_text: input.targetUserId, action: 'user.deleted', reason: input.reason, metadata: { confirmation: 'email_matched' } }).select('id').single();
        if (auditError) throw auditError;
        const { error } = await service.auth.admin.deleteUser(input.targetUserId);
        if (error) { await service.from('admin_audit_log').update({ action: 'user.mutation_failed', metadata: { attempted_action: 'user.deleted', error: error.message } }).eq('id', audit.id); throw error; }
      } else {
        const restoring = input.action === 'restore_user';
        const action = restoring ? 'user.restored' : 'user.suspended';
        const { data: audit, error: auditError } = await service.from('admin_audit_log').insert({ actor_user_id: identity.userId, target_user_id: input.targetUserId, target_user_id_text: input.targetUserId, action, reason: input.reason, metadata: { status: 'requested' } }).select('id').single();
        if (auditError) throw auditError;
        const { error } = await service.auth.admin.updateUserById(input.targetUserId, { ban_duration: restoring ? 'none' : '876000h' });
        if (error) { await service.from('admin_audit_log').update({ action: 'user.mutation_failed', metadata: { attempted_action: action, error: error.message } }).eq('id', audit.id); throw error; }
        await service.from('admin_audit_log').update({ metadata: { status: 'completed' } }).eq('id', audit.id);
      }
    }
    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Mutation failed';
    if (input.action === 'grant_override' || input.action === 'revoke_override') await auditFailure(identity.userId, input.targetUserId, input.reason, input.action, message);
    return NextResponse.json({ error: 'Operation failed and was not completed' }, { status: 500 });
  }
}
