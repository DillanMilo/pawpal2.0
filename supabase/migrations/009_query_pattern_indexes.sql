-- Indexes matching the app's actual query patterns.
--
-- AppointmentService.getPetAppointments filters by pet_id and orders by
-- date_time; ReminderService.getPetReminders filters by pet_id and orders by
-- due_date; MedicalService queries filter by (pet_id, type). None of these
-- were covered by the original single-column indexes.

CREATE INDEX IF NOT EXISTS idx_appointments_pet_date_time
    ON public.appointments (pet_id, date_time)
    WHERE pet_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reminders_pet_due_date
    ON public.reminders (pet_id, due_date)
    WHERE pet_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_medical_records_pet_type
    ON public.medical_records (pet_id, type);
