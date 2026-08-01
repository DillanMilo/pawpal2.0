-- Private owner/admin dashboard foundation.
-- No admin is seeded automatically. Add the owner's existing auth user ID only
-- after reviewing it in Supabase Auth:
-- INSERT INTO public.admin_users (user_id, role) VALUES ('<owner-uuid>', 'owner');

CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('owner', 'admin')),
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id_text TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN (
    'entitlement.override_granted',
    'entitlement.override_revoked',
    'user.suspended',
    'user.restored',
    'user.deleted',
    'user.mutation_failed'
  )),
  reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 3),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at
  ON public.admin_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target
  ON public.admin_audit_log(target_user_id_text, created_at DESC);

CREATE TABLE IF NOT EXISTS public.admin_entitlement_overrides (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL CHECK (tier IN ('free', 'plus')),
  reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 3),
  expires_at TIMESTAMPTZ,
  original_entitlement JSONB NOT NULL,
  latest_billing_entitlement JSONB,
  active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_by UUID REFERENCES auth.users(id),
  revoked_at TIMESTAMPTZ,
  CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE INDEX IF NOT EXISTS idx_admin_entitlement_overrides_active
  ON public.admin_entitlement_overrides(active, expires_at);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_entitlement_overrides ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.admin_users FROM anon, authenticated;
REVOKE ALL ON public.admin_audit_log FROM anon, authenticated;
REVOKE ALL ON public.admin_entitlement_overrides FROM anon, authenticated;
GRANT ALL ON public.admin_users TO service_role;
GRANT ALL ON public.admin_audit_log TO service_role;
GRANT ALL ON public.admin_entitlement_overrides TO service_role;

CREATE OR REPLACE FUNCTION public.admin_apply_entitlement_override(
  p_actor_user_id UUID,
  p_target_user_id UUID,
  p_tier TEXT,
  p_reason TEXT,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_entitlement public.account_entitlements%ROWTYPE;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE user_id = p_actor_user_id AND enabled = true
  ) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;
  IF p_tier NOT IN ('free', 'plus') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;
  IF char_length(trim(p_reason)) < 3 THEN
    RAISE EXCEPTION 'An auditable reason is required';
  END IF;
  IF p_expires_at IS NOT NULL AND p_expires_at <= NOW() THEN
    RAISE EXCEPTION 'Expiry must be in the future';
  END IF;

  INSERT INTO public.account_entitlements (
    user_id, tier, status, source, current_period_ends_at
  ) VALUES (
    p_target_user_id, 'free', 'expired', 'promotional', NULL
  ) ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO current_entitlement
  FROM public.account_entitlements
  WHERE user_id = p_target_user_id
  FOR UPDATE;

  INSERT INTO public.admin_entitlement_overrides (
    user_id, tier, reason, expires_at, original_entitlement, created_by
  ) VALUES (
    p_target_user_id,
    p_tier,
    trim(p_reason),
    p_expires_at,
    to_jsonb(current_entitlement),
    p_actor_user_id
  )
  ON CONFLICT (user_id) DO UPDATE SET
    tier = EXCLUDED.tier,
    reason = EXCLUDED.reason,
    expires_at = EXCLUDED.expires_at,
    original_entitlement = CASE
      WHEN public.admin_entitlement_overrides.active
        THEN public.admin_entitlement_overrides.original_entitlement
      ELSE EXCLUDED.original_entitlement
    END,
    latest_billing_entitlement = CASE
      WHEN public.admin_entitlement_overrides.active
        THEN public.admin_entitlement_overrides.latest_billing_entitlement
      ELSE NULL
    END,
    active = true,
    created_by = EXCLUDED.created_by,
    updated_at = NOW(),
    revoked_by = NULL,
    revoked_at = NULL;

  UPDATE public.account_entitlements
  SET
    tier = p_tier,
    status = CASE WHEN p_tier = 'plus' THEN 'active' ELSE 'expired' END,
    source = 'promotional',
    trial_started_at = NULL,
    trial_ends_at = NULL,
    current_period_ends_at = CASE
      WHEN p_tier = 'plus' THEN COALESCE(p_expires_at, NOW() + INTERVAL '100 years')
      ELSE NULL
    END,
    product_id = 'manual_admin_override',
    store = NULL,
    will_renew = false,
    updated_at = NOW()
  WHERE user_id = p_target_user_id;

  INSERT INTO public.admin_audit_log (
    actor_user_id, target_user_id, target_user_id_text, action, reason, metadata
  ) VALUES (
    p_actor_user_id,
    p_target_user_id,
    p_target_user_id::TEXT,
    'entitlement.override_granted',
    trim(p_reason),
    jsonb_build_object('tier', p_tier, 'expires_at', p_expires_at)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_revoke_entitlement_override(
  p_actor_user_id UUID,
  p_target_user_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  override_row public.admin_entitlement_overrides%ROWTYPE;
  restored public.account_entitlements%ROWTYPE;
  restore_payload JSONB;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE user_id = p_actor_user_id AND enabled = true
  ) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;
  IF char_length(trim(p_reason)) < 3 THEN
    RAISE EXCEPTION 'An auditable reason is required';
  END IF;

  SELECT * INTO override_row
  FROM public.admin_entitlement_overrides
  WHERE user_id = p_target_user_id AND active = true
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active manual override';
  END IF;

  restore_payload := COALESCE(
    override_row.latest_billing_entitlement,
    override_row.original_entitlement
  );
  SELECT * INTO restored
  FROM jsonb_populate_record(NULL::public.account_entitlements, restore_payload);

  UPDATE public.account_entitlements SET
    tier = restored.tier,
    status = restored.status,
    source = restored.source,
    trial_started_at = restored.trial_started_at,
    trial_ends_at = restored.trial_ends_at,
    current_period_ends_at = restored.current_period_ends_at,
    product_id = restored.product_id,
    store = restored.store,
    external_customer_id = restored.external_customer_id,
    original_transaction_id = restored.original_transaction_id,
    will_renew = restored.will_renew,
    updated_at = NOW()
  WHERE user_id = p_target_user_id;

  UPDATE public.admin_entitlement_overrides SET
    active = false,
    revoked_by = p_actor_user_id,
    revoked_at = NOW(),
    updated_at = NOW()
  WHERE user_id = p_target_user_id;

  INSERT INTO public.admin_audit_log (
    actor_user_id, target_user_id, target_user_id_text, action, reason, metadata
  ) VALUES (
    p_actor_user_id,
    p_target_user_id,
    p_target_user_id::TEXT,
    'entitlement.override_revoked',
    trim(p_reason),
    jsonb_build_object(
      'restored_latest_billing_state',
      override_row.latest_billing_entitlement IS NOT NULL
    )
  );
END;
$$;

-- RevenueCat uses this function so store state is retained while a manual
-- override is active and restored cleanly when the override is revoked.
CREATE OR REPLACE FUNCTION public.apply_billing_entitlement_update(
  p_user_id UUID,
  p_entitlement JSONB
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.admin_entitlement_overrides
  SET latest_billing_entitlement = p_entitlement, updated_at = NOW()
  WHERE user_id = p_user_id
    AND active = true
    AND (expires_at IS NULL OR expires_at > NOW());

  IF FOUND THEN
    RETURN 'deferred_by_manual_override';
  END IF;

  INSERT INTO public.account_entitlements (
    user_id, tier, status, source, current_period_ends_at, product_id, store,
    external_customer_id, original_transaction_id, will_renew
  ) VALUES (
    p_user_id,
    p_entitlement->>'tier',
    p_entitlement->>'status',
    p_entitlement->>'source',
    NULLIF(p_entitlement->>'current_period_ends_at', '')::TIMESTAMPTZ,
    p_entitlement->>'product_id',
    p_entitlement->>'store',
    p_entitlement->>'external_customer_id',
    p_entitlement->>'original_transaction_id',
    COALESCE((p_entitlement->>'will_renew')::BOOLEAN, false)
  )
  ON CONFLICT (user_id) DO UPDATE SET
    tier = EXCLUDED.tier,
    status = EXCLUDED.status,
    source = EXCLUDED.source,
    current_period_ends_at = EXCLUDED.current_period_ends_at,
    product_id = EXCLUDED.product_id,
    store = EXCLUDED.store,
    external_customer_id = EXCLUDED.external_customer_id,
    original_transaction_id = EXCLUDED.original_transaction_id,
    will_renew = EXCLUDED.will_renew,
    updated_at = NOW();

  RETURN 'applied';
END;
$$;

REVOKE ALL ON FUNCTION public.admin_apply_entitlement_override(UUID, UUID, TEXT, TEXT, TIMESTAMPTZ) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_revoke_entitlement_override(UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.apply_billing_entitlement_update(UUID, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_apply_entitlement_override(UUID, UUID, TEXT, TEXT, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_revoke_entitlement_override(UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.apply_billing_entitlement_update(UUID, JSONB) TO service_role;
