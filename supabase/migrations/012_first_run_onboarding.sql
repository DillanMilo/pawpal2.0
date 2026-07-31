-- Resumable first-run setup and product tour state.
-- Existing accounts are marked complete so this only affects genuinely new users.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS onboarding_step SMALLINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS onboarding_draft JSONB NOT NULL DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS app_tour_step SMALLINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS app_tour_completed_at TIMESTAMPTZ;

UPDATE public.users
SET
  onboarding_completed_at = COALESCE(onboarding_completed_at, NOW()),
  app_tour_completed_at = COALESCE(app_tour_completed_at, NOW());

ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_onboarding_step_range,
  ADD CONSTRAINT users_onboarding_step_range
    CHECK (onboarding_step BETWEEN 0 AND 2),
  DROP CONSTRAINT IF EXISTS users_app_tour_step_range,
  ADD CONSTRAINT users_app_tour_step_range
    CHECK (app_tour_step BETWEEN 0 AND 4);
