-- Subscription and no-card trial foundation.
-- RevenueCat/Stripe webhooks are the only writers after the signup trigger.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS has_seen_pricing BOOLEAN NOT NULL DEFAULT false;

-- Existing accounts should not be forced through the new post-signup screen.
UPDATE public.users
SET has_seen_pricing = true
WHERE has_seen_pricing = false;

CREATE TABLE IF NOT EXISTS public.account_entitlements (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'plus'
    CHECK (tier IN ('free', 'plus')),
  status TEXT NOT NULL DEFAULT 'trialing'
    CHECK (status IN (
      'trialing', 'active', 'canceled', 'past_due', 'expired'
    )),
  source TEXT NOT NULL DEFAULT 'pawpal_trial'
    CHECK (source IN (
      'pawpal_trial', 'app_store', 'play_store', 'stripe', 'promotional'
    )),
  trial_started_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  current_period_ends_at TIMESTAMPTZ,
  product_id TEXT,
  store TEXT,
  external_customer_id TEXT,
  original_transaction_id TEXT,
  will_renew BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_trial_window CHECK (
    trial_ends_at IS NULL
    OR trial_started_at IS NULL
    OR trial_ends_at > trial_started_at
  )
);

CREATE INDEX IF NOT EXISTS idx_account_entitlements_status
  ON public.account_entitlements(status);
CREATE INDEX IF NOT EXISTS idx_account_entitlements_period_end
  ON public.account_entitlements(current_period_ends_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_account_entitlements_original_transaction
  ON public.account_entitlements(original_transaction_id)
  WHERE original_transaction_id IS NOT NULL;

ALTER TABLE public.account_entitlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own entitlement"
  ON public.account_entitlements;
CREATE POLICY "Users can view own entitlement"
  ON public.account_entitlements
  FOR SELECT
  USING (auth.uid() = user_id);

-- Do not add INSERT/UPDATE/DELETE policies for clients. Subscription state is
-- created by the trigger and changed only with the service role in webhooks.
REVOKE ALL ON public.account_entitlements FROM anon;
GRANT SELECT ON public.account_entitlements TO authenticated;

CREATE TABLE IF NOT EXISTS public.subscription_events (
  event_id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'revenuecat',
  payload JSONB NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.subscription_events FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_trial_for_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.account_entitlements (
    user_id,
    tier,
    status,
    source,
    trial_started_at,
    trial_ends_at
  )
  VALUES (
    NEW.id,
    'plus',
    'trialing',
    'pawpal_trial',
    NOW(),
    NOW() + INTERVAL '14 days'
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_public_user_created_trial ON public.users;
CREATE TRIGGER on_public_user_created_trial
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.create_trial_for_new_user();

-- Give accounts that existed when monetization was introduced the same trial.
INSERT INTO public.account_entitlements (
  user_id,
  tier,
  status,
  source,
  trial_started_at,
  trial_ends_at
)
SELECT
  id,
  'plus',
  'trialing',
  'pawpal_trial',
  NOW(),
  NOW() + INTERVAL '14 days'
FROM public.users
ON CONFLICT (user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.has_plus_access(
  check_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.account_entitlements entitlement
    WHERE entitlement.user_id = check_user_id
      AND check_user_id = auth.uid()
      AND entitlement.tier = 'plus'
      AND (
        (
          entitlement.status = 'trialing'
          AND entitlement.trial_ends_at > NOW()
        )
        OR (
          entitlement.status IN ('active', 'canceled', 'past_due')
          AND entitlement.current_period_ends_at > NOW()
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.has_plus_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_plus_access(UUID) TO authenticated;

-- Enforce the launch free-tier limits in PostgreSQL, not only in Flutter.
DROP POLICY IF EXISTS "Users can insert own pets" ON public.pets;
CREATE POLICY "Users can insert own pets"
  ON public.pets
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      public.has_plus_access(user_id)
      OR (SELECT COUNT(*) FROM public.pets WHERE pets.user_id = auth.uid()) < 1
    )
  );

DROP POLICY IF EXISTS "Users can insert medical records for own pets"
  ON public.medical_records;
CREATE POLICY "Users can insert medical records for own pets"
  ON public.medical_records
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = medical_records.pet_id
        AND pets.user_id = auth.uid()
    )
    AND (
      public.has_plus_access(auth.uid())
      OR (
        SELECT COUNT(*)
        FROM public.medical_records existing_record
        JOIN public.pets owner_pet ON owner_pet.id = existing_record.pet_id
        WHERE owner_pet.user_id = auth.uid()
      ) < 20
    )
  );

DROP POLICY IF EXISTS "Users can insert own reminders" ON public.reminders;
CREATE POLICY "Users can insert own reminders"
  ON public.reminders
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = reminders.pet_id
          AND pets.user_id = auth.uid()
      )
    )
    AND (
      public.has_plus_access(user_id)
      OR (
        SELECT COUNT(*)
        FROM public.reminders existing_reminder
        WHERE existing_reminder.user_id = auth.uid()
          AND existing_reminder.is_completed = false
      ) < 5
    )
    AND (
      is_recurring = false
      OR public.has_plus_access(user_id)
    )
  );

-- Base users may complete, reschedule, or edit one-time reminders, but cannot
-- convert a reminder into recurring automation without an active Plus grant.
DROP POLICY IF EXISTS "Users can update own reminders" ON public.reminders;
CREATE POLICY "Users can update own reminders"
  ON public.reminders
  FOR UPDATE
  USING (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = reminders.pet_id
          AND pets.user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = reminders.pet_id
          AND pets.user_id = auth.uid()
      )
    )
    AND (
      is_recurring = false
      OR public.has_plus_access(user_id)
    )
  );

-- Free users retain read/delete access to their documents. New uploads and
-- replacements require Plus, preventing data lock-in after a downgrade.
DROP POLICY IF EXISTS "Users can upload medical documents for own pets"
  ON storage.objects;
DROP POLICY IF EXISTS "Users can manage medical documents for own pets"
  ON storage.objects;

CREATE POLICY "Users can read medical documents for own pets"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'medical-documents'
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[1]
        AND pets.user_id = auth.uid()
    )
  );

CREATE POLICY "Plus users can upload medical documents"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'medical-documents'
    AND public.has_plus_access(auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[1]
        AND pets.user_id = auth.uid()
    )
  );

CREATE POLICY "Plus users can update medical documents"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'medical-documents'
    AND public.has_plus_access(auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[1]
        AND pets.user_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'medical-documents'
    AND public.has_plus_access(auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[1]
        AND pets.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete medical documents for own pets"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'medical-documents'
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[1]
        AND pets.user_id = auth.uid()
    )
  );

DROP TRIGGER IF EXISTS set_account_entitlements_updated_at
  ON public.account_entitlements;
CREATE TRIGGER set_account_entitlements_updated_at
  BEFORE UPDATE ON public.account_entitlements
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
