-- Run in Supabase SQL Editor after tables exist.
-- Fixes patient "link code" (otp_artifacts) and caregiver link flow.

-- ---------- otp_artifacts ----------
drop policy if exists otp_artifacts_insert_patient on public.otp_artifacts;
create policy otp_artifacts_insert_patient
on public.otp_artifacts for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'patient'
      and p.phone = patient_phone
  )
);

drop policy if exists otp_artifacts_select_authenticated on public.otp_artifacts;
create policy otp_artifacts_select_authenticated
on public.otp_artifacts for select
to authenticated
using (true);

drop policy if exists otp_artifacts_update_caregiver on public.otp_artifacts;
create policy otp_artifacts_update_caregiver
on public.otp_artifacts for update
to authenticated
using (used_at is null)
with check (caregiver_id = auth.uid());

-- ---------- profiles (caregiver must find patient by phone) ----------
drop policy if exists profiles_select_patients on public.profiles;
create policy profiles_select_patients
on public.profiles for select
to authenticated
using (role = 'patient');

-- ---------- caregiver_patient_links ----------
drop policy if exists cpl_insert_own on public.caregiver_patient_links;
create policy cpl_insert_own
on public.caregiver_patient_links for insert
to authenticated
with check (caregiver_id = auth.uid());

drop policy if exists cpl_select_participant on public.caregiver_patient_links;
create policy cpl_select_participant
on public.caregiver_patient_links for select
to authenticated
using (caregiver_id = auth.uid() or patient_id = auth.uid());

drop policy if exists cpl_update_caregiver on public.caregiver_patient_links;
create policy cpl_update_caregiver
on public.caregiver_patient_links for update
to authenticated
using (caregiver_id = auth.uid())
with check (caregiver_id = auth.uid());

-- ---------- doctor_patient_links ----------
drop policy if exists dpl_insert_own on public.doctor_patient_links;
create policy dpl_insert_own
on public.doctor_patient_links for insert
to authenticated
with check (doctor_id = auth.uid());

drop policy if exists dpl_select_participant on public.doctor_patient_links;
create policy dpl_select_participant
on public.doctor_patient_links for select
to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists dpl_update_doctor on public.doctor_patient_links;
create policy dpl_update_doctor
on public.doctor_patient_links for update
to authenticated
using (doctor_id = auth.uid())
with check (doctor_id = auth.uid());

-- Doctors can mark link codes used (same otp_artifacts table as caregivers).
drop policy if exists otp_artifacts_update_doctor on public.otp_artifacts;
create policy otp_artifacts_update_doctor
on public.otp_artifacts for update
to authenticated
using (used_at is null)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'doctor'
  )
);
