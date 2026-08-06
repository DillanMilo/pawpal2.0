-- Quota checks must not query an RLS-protected table from that table's own
-- policy. Security-definer helpers perform the counts without recursive policy
-- evaluation while still refusing to inspect another user's data.

CREATE OR REPLACE FUNCTION public.owned_pet_count(check_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN check_user_id = auth.uid() THEN (
      SELECT COUNT(*) FROM public.pets WHERE pets.user_id = check_user_id
    )
    ELSE 0
  END;
$$;

CREATE OR REPLACE FUNCTION public.owned_medical_record_count(check_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN check_user_id = auth.uid() THEN (
      SELECT COUNT(*)
      FROM public.medical_records record
      JOIN public.pets pet ON pet.id = record.pet_id
      WHERE pet.user_id = check_user_id
    )
    ELSE 0
  END;
$$;

CREATE OR REPLACE FUNCTION public.active_reminder_count(check_user_id UUID)
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN check_user_id = auth.uid() THEN (
      SELECT COUNT(*)
      FROM public.reminders
      WHERE reminders.user_id = check_user_id
        AND reminders.is_completed = false
    )
    ELSE 0
  END;
$$;

REVOKE ALL ON FUNCTION public.owned_pet_count(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.owned_medical_record_count(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.active_reminder_count(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.owned_pet_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owned_medical_record_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.active_reminder_count(UUID) TO authenticated;

DROP POLICY IF EXISTS "Users can insert own pets" ON public.pets;
CREATE POLICY "Users can insert own pets"
  ON public.pets
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      public.has_plus_access(user_id)
      OR public.owned_pet_count(user_id) < 1
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
      OR public.owned_medical_record_count(auth.uid()) < 20
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
      OR public.active_reminder_count(user_id) < 5
    )
    AND (
      is_recurring = false
      OR public.has_plus_access(user_id)
    )
  );

-- PawPoints are authoritative in PostgreSQL. Every care entry still saves
-- after the cap; only the awarded points fall to the remaining daily amount.
CREATE OR REPLACE FUNCTION public.apply_daily_pawpoints_cap()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_points INTEGER;
  bonus_per_ten INTEGER;
  per_activity_cap INTEGER;
  calculated_points INTEGER;
  earned_today INTEGER;
  day_start TIMESTAMPTZ;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Do not let a client backdate a new entry to escape today's cap.
    NEW.created_at := statement_timestamp();
  ELSE
    NEW.created_at := OLD.created_at;
  END IF;

  base_points := CASE NEW.type
    WHEN 'Walk' THEN 10
    WHEN 'Play' THEN 8
    WHEN 'Train' THEN 15
    WHEN 'Feed' THEN 5
    WHEN 'Groom' THEN 7
    WHEN 'Vet Visit' THEN 20
    WHEN 'Social' THEN 12
    WHEN 'Rest' THEN 3
    ELSE 5
  END;

  bonus_per_ten := CASE NEW.type
    WHEN 'Walk' THEN 2
    WHEN 'Play' THEN 1
    WHEN 'Train' THEN 2
    WHEN 'Groom' THEN 1
    WHEN 'Social' THEN 1
    ELSE 0
  END;

  per_activity_cap := CASE NEW.type
    WHEN 'Walk' THEN 30
    WHEN 'Play' THEN 22
    WHEN 'Train' THEN 35
    WHEN 'Feed' THEN 5
    WHEN 'Groom' THEN 16
    WHEN 'Vet Visit' THEN 20
    WHEN 'Social' THEN 24
    WHEN 'Rest' THEN 3
    ELSE base_points
  END;

  calculated_points := LEAST(
    per_activity_cap,
    base_points + (
      GREATEST(COALESCE(NEW.duration_minutes, 0), 0) / 10
    ) * bonus_per_ten
  );

  day_start := date_trunc('day', NEW.created_at AT TIME ZONE 'UTC')
    AT TIME ZONE 'UTC';

  -- Serialize awards for the same account/day so simultaneous requests
  -- cannot race past the daily cap.
  PERFORM pg_advisory_xact_lock(
    hashtextextended(NEW.user_id::TEXT || day_start::TEXT, 0)
  );

  SELECT COALESCE(SUM(activity.points), 0)::INTEGER
  INTO earned_today
  FROM public.activities activity
  WHERE activity.user_id = NEW.user_id
    AND activity.created_at >= day_start
    AND activity.created_at < day_start + INTERVAL '1 day'
    AND (NEW.id IS NULL OR activity.id <> NEW.id);

  NEW.points := LEAST(calculated_points, GREATEST(0, 100 - earned_today));
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_daily_pawpoints_cap() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS apply_daily_pawpoints_cap ON public.activities;
CREATE TRIGGER apply_daily_pawpoints_cap
  BEFORE INSERT OR UPDATE ON public.activities
  FOR EACH ROW EXECUTE FUNCTION public.apply_daily_pawpoints_cap();

COMMENT ON FUNCTION public.apply_daily_pawpoints_cap() IS
  'Calculates authoritative activity rewards and caps each account at 100 PawPoints per UTC day.';
