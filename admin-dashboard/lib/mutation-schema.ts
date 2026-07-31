import { z } from 'zod';

const base = z.object({
  targetUserId: z.string().uuid(),
  reason: z.string().trim().min(3).max(500),
});

export const adminMutationSchema = z.discriminatedUnion('action', [
  base.extend({
    action: z.literal('grant_override'),
    tier: z.enum(['free', 'plus']),
    expiresAt: z.string().datetime().nullable(),
    confirmed: z.literal(true),
  }),
  base.extend({
    action: z.literal('revoke_override'),
    confirmed: z.literal(true),
  }),
  base.extend({
    action: z.enum(['suspend_user', 'restore_user']),
    confirmed: z.literal(true),
  }),
  base.extend({
    action: z.literal('delete_user'),
    confirmation: z.string().email(),
  }),
]);

export function hasValidDeleteConfirmation(
  confirmation: string,
  targetEmail: string,
) {
  return confirmation.trim().toLowerCase() === targetEmail.trim().toLowerCase();
}

export function isAllowedMutationOrigin(
  origin: string | null,
  configuredOrigin: string,
) {
  if (!origin) return false;
  try {
    return new URL(origin).origin === new URL(configuredOrigin).origin;
  } catch {
    return false;
  }
}
