-- Pet progression points remain derived from persisted activity rows.
-- Only the user's equipped cosmetic choices need their own durable fields.

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS profile_frame_id TEXT NOT NULL DEFAULT 'classic',
  ADD COLUMN IF NOT EXISTS profile_accessory_id TEXT NOT NULL DEFAULT 'none';

COMMENT ON COLUMN public.pets.profile_frame_id IS
  'Equipped profile frame unlocked through the pet PawPoint level.';

COMMENT ON COLUMN public.pets.profile_accessory_id IS
  'Equipped profile accessory unlocked through the pet PawPoint level.';
