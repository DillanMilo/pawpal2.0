-- PawPal production hardening
-- Adds storage buckets/policies, updated_at triggers, and query indexes.

-- Storage buckets used by the Flutter app.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'profile-photos',
    'profile-photos',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'pet-photos',
    'pet-photos',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'activity-photos',
    'activity-photos',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'medical-documents',
    'medical-documents',
    true,
    20971520,
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
  )
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage object policies. Public buckets expose read URLs, while writes remain user-owned.
DROP POLICY IF EXISTS "Users can read own PawPal storage objects" ON storage.objects;
CREATE POLICY "Users can read own PawPal storage objects"
ON storage.objects
FOR SELECT
USING (
  bucket_id IN ('profile-photos', 'pet-photos', 'activity-photos', 'medical-documents')
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "Users can upload own PawPal storage objects" ON storage.objects;
CREATE POLICY "Users can upload own PawPal storage objects"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id IN ('profile-photos', 'pet-photos', 'activity-photos', 'medical-documents')
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "Users can update own PawPal storage objects" ON storage.objects;
CREATE POLICY "Users can update own PawPal storage objects"
ON storage.objects
FOR UPDATE
USING (
  bucket_id IN ('profile-photos', 'pet-photos', 'activity-photos', 'medical-documents')
  AND owner = auth.uid()
)
WITH CHECK (
  bucket_id IN ('profile-photos', 'pet-photos', 'activity-photos', 'medical-documents')
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "Users can delete own PawPal storage objects" ON storage.objects;
CREATE POLICY "Users can delete own PawPal storage objects"
ON storage.objects
FOR DELETE
USING (
  bucket_id IN ('profile-photos', 'pet-photos', 'activity-photos', 'medical-documents')
  AND owner = auth.uid()
);

-- Keep updated_at consistent from the database side as well as the app side.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_users_updated_at ON public.users;
CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_pets_updated_at ON public.pets;
CREATE TRIGGER set_pets_updated_at
  BEFORE UPDATE ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_medical_records_updated_at ON public.medical_records;
CREATE TRIGGER set_medical_records_updated_at
  BEFORE UPDATE ON public.medical_records
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_appointments_updated_at ON public.appointments;
CREATE TRIGGER set_appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_reminders_updated_at ON public.reminders;
CREATE TRIGGER set_reminders_updated_at
  BEFORE UPDATE ON public.reminders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Query indexes matching the app's common filters.
CREATE INDEX IF NOT EXISTS idx_medical_records_pet_type_date
  ON public.medical_records (pet_id, type, date DESC);

CREATE INDEX IF NOT EXISTS idx_medical_records_pet_next_due
  ON public.medical_records (pet_id, next_due_date)
  WHERE next_due_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reminders_user_completed_due
  ON public.reminders (user_id, is_completed, due_date);

CREATE INDEX IF NOT EXISTS idx_appointments_user_completed_date
  ON public.appointments (user_id, is_completed, date_time);

CREATE UNIQUE INDEX IF NOT EXISTS idx_favorite_providers_user_place_unique
  ON public.favorite_providers (user_id, place_id)
  WHERE place_id IS NOT NULL;
