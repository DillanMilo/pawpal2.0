-- Persist editable pet card header images and user-controlled pet ordering.

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS cover_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0;

WITH ordered_pets AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY user_id
      ORDER BY created_at ASC, id ASC
    ) - 1 AS next_display_order
  FROM public.pets
)
UPDATE public.pets
SET display_order = ordered_pets.next_display_order
FROM ordered_pets
WHERE public.pets.id = ordered_pets.id;

CREATE INDEX IF NOT EXISTS idx_pets_user_display_order
  ON public.pets (user_id, display_order, created_at);
