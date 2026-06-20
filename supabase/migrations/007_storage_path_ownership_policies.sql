-- Make storage writes independent of storage.objects.owner timing.
-- Pet and medical document object paths start with the owning pet id.

DROP POLICY IF EXISTS "Users can upload pet photos for own pets" ON storage.objects;
CREATE POLICY "Users can upload pet photos for own pets"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'pet-photos'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage pet photos for own pets" ON storage.objects;
CREATE POLICY "Users can manage pet photos for own pets"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'pet-photos'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'pet-photos'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can upload profile photos to own folder" ON storage.objects;
CREATE POLICY "Users can upload profile photos to own folder"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can manage profile photos in own folder" ON storage.objects;
CREATE POLICY "Users can manage profile photos in own folder"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can upload medical documents for own pets" ON storage.objects;
CREATE POLICY "Users can upload medical documents for own pets"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'medical-documents'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can manage medical documents for own pets" ON storage.objects;
CREATE POLICY "Users can manage medical documents for own pets"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'medical-documents'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'medical-documents'
  AND EXISTS (
    SELECT 1
    FROM public.pets
    WHERE pets.id::text = (storage.foldername(name))[1]
      AND pets.user_id = auth.uid()
  )
);
