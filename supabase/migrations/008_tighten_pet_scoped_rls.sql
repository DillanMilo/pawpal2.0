-- Tighten policies that depend on pet ownership.
-- Supabase RLS policies are permissive by default, so broad legacy storage
-- policies must be removed before stricter path-based policies are meaningful.

DROP POLICY IF EXISTS "Users can read own PawPal storage objects" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own PawPal storage objects" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own PawPal storage objects" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own PawPal storage objects" ON storage.objects;

DROP POLICY IF EXISTS "Users can manage activity photos in own folder" ON storage.objects;
CREATE POLICY "Users can manage activity photos in own folder"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'activity-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'activity-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own pets" ON public.pets;
CREATE POLICY "Users can update own pets" ON public.pets
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update medical records for own pets" ON public.medical_records;
CREATE POLICY "Users can update medical records for own pets" ON public.medical_records
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = medical_records.pet_id
        AND pets.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = medical_records.pet_id
        AND pets.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can view own activities" ON public.activities;
CREATE POLICY "Users can view own activities" ON public.activities
  FOR SELECT
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = activities.pet_id
        AND pets.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert own activities" ON public.activities;
CREATE POLICY "Users can insert own activities" ON public.activities
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = activities.pet_id
        AND pets.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own activities" ON public.activities;
CREATE POLICY "Users can update own activities" ON public.activities
  FOR UPDATE
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = activities.pet_id
        AND pets.user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = activities.pet_id
        AND pets.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete own activities" ON public.activities;
CREATE POLICY "Users can delete own activities" ON public.activities
  FOR DELETE
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id = activities.pet_id
        AND pets.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
CREATE POLICY "Users can view own appointments" ON public.appointments
  FOR SELECT
  USING (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = appointments.pet_id
          AND pets.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can insert own appointments" ON public.appointments;
CREATE POLICY "Users can insert own appointments" ON public.appointments
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = appointments.pet_id
          AND pets.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
CREATE POLICY "Users can update own appointments" ON public.appointments
  FOR UPDATE
  USING (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = appointments.pet_id
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
        WHERE pets.id = appointments.pet_id
          AND pets.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
CREATE POLICY "Users can delete own appointments" ON public.appointments
  FOR DELETE
  USING (
    auth.uid() = user_id
    AND (
      pet_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.pets
        WHERE pets.id = appointments.pet_id
          AND pets.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can view own reminders" ON public.reminders;
CREATE POLICY "Users can view own reminders" ON public.reminders
  FOR SELECT
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
  );

DROP POLICY IF EXISTS "Users can insert own reminders" ON public.reminders;
CREATE POLICY "Users can insert own reminders" ON public.reminders
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
  );

DROP POLICY IF EXISTS "Users can update own reminders" ON public.reminders;
CREATE POLICY "Users can update own reminders" ON public.reminders
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
  );

DROP POLICY IF EXISTS "Users can delete own reminders" ON public.reminders;
CREATE POLICY "Users can delete own reminders" ON public.reminders
  FOR DELETE
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
  );

DROP POLICY IF EXISTS "Users can update own favorite providers" ON public.favorite_providers;
CREATE POLICY "Users can update own favorite providers" ON public.favorite_providers
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
