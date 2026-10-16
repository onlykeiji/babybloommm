-- Completed vaccine records are historical logs, not upcoming events.
-- Clear old reminder flags and keep future writes consistent with the UI.

update public.vaccine_log_entries
set reminder_enabled = false
where status = 'completed' and reminder_enabled = true;

alter table public.vaccine_log_entries
  drop constraint if exists completed_vaccines_cannot_have_reminders;

alter table public.vaccine_log_entries
  add constraint completed_vaccines_cannot_have_reminders
  check (status <> 'completed' or reminder_enabled = false);
