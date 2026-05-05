-- Medical records can contain sensitive health information.
-- Keep document objects private and serve them only through signed URLs.
UPDATE storage.buckets
SET public = false
WHERE id = 'medical-documents';
