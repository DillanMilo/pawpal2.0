import { describe, expect, it } from 'vitest';
import { adminMutationSchema, hasValidDeleteConfirmation, isAllowedMutationOrigin } from '../lib/mutation-schema';

const targetUserId = '11111111-1111-4111-8111-111111111111';

describe('admin mutation confirmations', () => {
  it('requires explicit confirmation and an auditable reason for plan changes', () => {
    expect(adminMutationSchema.safeParse({ action: 'grant_override', targetUserId, tier: 'plus', expiresAt: null, reason: 'Support courtesy', confirmed: true }).success).toBe(true);
    expect(adminMutationSchema.safeParse({ action: 'grant_override', targetUserId, tier: 'plus', expiresAt: null, reason: '', confirmed: true }).success).toBe(false);
    expect(adminMutationSchema.safeParse({ action: 'grant_override', targetUserId, tier: 'plus', expiresAt: null, reason: 'Support courtesy', confirmed: false }).success).toBe(false);
  });

  it('requires an email-shaped typed confirmation for permanent deletion', () => {
    expect(adminMutationSchema.safeParse({ action: 'delete_user', targetUserId, reason: 'Owner-requested erasure', confirmation: 'owner@example.com' }).success).toBe(true);
    expect(adminMutationSchema.safeParse({ action: 'delete_user', targetUserId, reason: 'Owner-requested erasure', confirmation: 'DELETE' }).success).toBe(false);
    expect(hasValidDeleteConfirmation('Owner@Example.com', 'owner@example.com')).toBe(true);
    expect(hasValidDeleteConfirmation('other@example.com', 'owner@example.com')).toBe(false);
  });

  it('rejects cross-origin mutations', () => {
    expect(isAllowedMutationOrigin('https://pawpal20.vercel.app', 'https://pawpal20.vercel.app')).toBe(true);
    expect(isAllowedMutationOrigin('https://evil.example', 'https://pawpal20.vercel.app')).toBe(false);
    expect(isAllowedMutationOrigin(null, 'https://pawpal20.vercel.app')).toBe(false);
  });
});
