-- Run in Supabase SQL Editor after caregiver_patient_links exist.
-- Fixes "Save Medication" and related reads (medications + schedules + dose_logs).

-- Helper: active caregiver ↔ patient link
create or replace function public.caregiver_has_patient(p_patient_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1
    from public.caregiver_patient_links cpl
    where cpl.caregiver_id = auth.uid()
      and cpl.patient_id = p_patient_id
      and cpl.status = 'active'
  );
$$;

-- ---------- medications ----------
drop policy if exists medications_select on public.medications;
create policy medications_select
on public.medications for select
to authenticated
using (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
  or exists (
    select 1
    from public.doctor_patient_links dpl
    where dpl.doctor_id = auth.uid()
      and dpl.patient_id = medications.patient_id
      and dpl.status = 'active'
  )
);

drop policy if exists medications_insert_caregiver on public.medications;
create policy medications_insert_caregiver
on public.medications for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.caregiver_has_patient(patient_id)
);

drop policy if exists medications_update on public.medications;
create policy medications_update
on public.medications for update
to authenticated
using (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
)
with check (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
);

drop policy if exists medications_delete_caregiver on public.medications;
create policy medications_delete_caregiver
on public.medications for delete
to authenticated
using (public.caregiver_has_patient(patient_id));

-- ---------- medication_schedules ----------
drop policy if exists med_schedules_select on public.medication_schedules;
create policy med_schedules_select
on public.medication_schedules for select
to authenticated
using (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and (
        m.patient_id = auth.uid()
        or public.caregiver_has_patient(m.patient_id)
        or exists (
          select 1 from public.doctor_patient_links dpl
          where dpl.doctor_id = auth.uid()
            and dpl.patient_id = m.patient_id
            and dpl.status = 'active'
        )
      )
  )
);

drop policy if exists med_schedules_insert on public.medication_schedules;
create policy med_schedules_insert
on public.medication_schedules for insert
to authenticated
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

drop policy if exists med_schedules_update on public.medication_schedules;
create policy med_schedules_update
on public.medication_schedules for update
to authenticated
using (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and public.caregiver_has_patient(m.patient_id)
  )
)
with check (
  exists (
    select 1 from public.medications m
    where m.id = medication_id
      and public.caregiver_has_patient(m.patient_id)
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
      and public.caregiver_has_patient(m.patient_id)
  )
);

-- ---------- dose_logs (patient confirm + caregiver/doctor read) ----------
drop policy if exists dose_logs_select on public.dose_logs;
create policy dose_logs_select
on public.dose_logs for select
to authenticated
using (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
  or exists (
    select 1 from public.doctor_patient_links dpl
    where dpl.doctor_id = auth.uid()
      and dpl.patient_id = dose_logs.patient_id
      and dpl.status = 'active'
  )
);

drop policy if exists dose_logs_insert on public.dose_logs;
create policy dose_logs_insert
on public.dose_logs for insert
to authenticated
with check (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
);

drop policy if exists dose_logs_update on public.dose_logs;
create policy dose_logs_update
on public.dose_logs for update
to authenticated
using (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
)
with check (
  patient_id = auth.uid()
  or public.caregiver_has_patient(patient_id)
);
