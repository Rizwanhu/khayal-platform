-- Run in Supabase SQL Editor after medications_rls.sql
-- Lets patients add/edit their own medications and schedules (solo patients without caregiver).

drop policy if exists medications_insert_patient on public.medications;
create policy medications_insert_patient
on public.medications for insert
to authenticated
with check (
  patient_id = auth.uid()
  and created_by = auth.uid()
);

drop policy if exists med_schedules_update on public.medication_schedules;
create policy med_schedules_update
on public.medication_schedules for update
to authenticated
using (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and (
        m.patient_id = auth.uid()
        or public.caregiver_has_patient(m.patient_id)
      )
  )
)
with check (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and (
        m.patient_id = auth.uid()
        or public.caregiver_has_patient(m.patient_id)
      )
  )
);

drop policy if exists med_schedules_delete on public.medication_schedules;
create policy med_schedules_delete
on public.medication_schedules for delete
to authenticated
using (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and (
        m.patient_id = auth.uid()
        or public.caregiver_has_patient(m.patient_id)
      )
  )
);
