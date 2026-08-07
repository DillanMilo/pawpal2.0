-- One-time, resumable contextual guidance introduced after the main app tour.
-- Existing and new accounts receive each short tip once. Completion is stored
-- per account so the tips stay dismissed across devices and app reinstalls.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS quick_actions_tour_completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS pet_profile_tour_completed_at TIMESTAMPTZ;
