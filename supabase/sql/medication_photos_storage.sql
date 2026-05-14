-- Khayal: medication pill photos (Supabase Storage + DB column)
--
-- BEFORE running this script:
-- 1) Dashboard → Storage → New bucket
--    Name: medication-photos
--    Public: OFF (private bucket)
--    Optional: file size limit 5 MB, allowed MIME image/jpeg, image/png, image/webp
--
-- 2) Run this entire file in SQL Editor (can re-run safely).

-- ---------------------------------------------------------------------------
-- Table: store object path inside the bucket (not a public URL)
-- ---------------------------------------------------------------------------
alter table public.medications
  add column if not exists image_storage_path text;

comment on column public.medications.image_storage_path is
  'Path inside bucket medication-photos, e.g. {patient_id}/{medication_id}.jpg. App uses signed URLs.';

-- ---------------------------------------------------------------------------
-- Storage RLS: path layout  {patient_id}/{medication_id}.{ext}
-- split_part(name, '/', 1) = patient UUID folder
-- ---------------------------------------------------------------------------

-- Remove old policies if you re-run this file (ignore errors if none exist)
drop policy if exists "med_photos_select_patient" on storage.objects;
drop policy if exists "med_photos_select_caregiver" on storage.objects;
drop policy if exists "med_photos_select_doctor" on storage.objects;
drop policy if exists "med_photos_insert_caregiver" on storage.objects;
drop policy if exists "med_photos_update_caregiver" on storage.objects;
drop policy if exists "med_photos_delete_caregiver" on storage.objects;

-- Patient can view images for their own medications folder
create policy "med_photos_select_patient"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'medication-photos'
  and split_part(name, '/', 1)::uuid = auth.uid()
);

-- Linked caregiver can view patient folder
create policy "med_photos_select_caregiver"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'medication-photos'
  and exists (
    select 1
    from public.caregiver_patient_links cpl
    where cpl.caregiver_id = auth.uid()
      and cpl.status = 'active'
      and cpl.patient_id = split_part(name, '/', 1)::uuid
  )
);

-- Assigned doctor can view patient folder
create policy "med_photos_select_doctor"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'medication-photos'
  and exists (
    select 1
    from public.doctor_patient_links dpl
    where dpl.doctor_id = auth.uid()
      and dpl.status = 'active'
      and dpl.patient_id = split_part(name, '/', 1)::uuid
  )
);

-- Only linked caregivers upload into a patient folder they manage
create policy "med_photos_insert_caregiver"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'medication-photos'
  and exists (
    select 1
    from public.caregiver_patient_links cpl
    where cpl.caregiver_id = auth.uid()
      and cpl.status = 'active'
      and cpl.patient_id = split_part(name, '/', 1)::uuid
  )
);

-- Replace image (upsert) / metadata updates
create policy "med_photos_update_caregiver"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'medication-photos'
  and exists (
    select 1
    from public.caregiver_patient_links cpl
    where cpl.caregiver_id = auth.uid()
      and cpl.status = 'active'
      and cpl.patient_id = split_part(name, '/', 1)::uuid
  )
);

create policy "med_photos_delete_caregiver"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'medication-photos'
  and exists (
    select 1
    from public.caregiver_patient_links cpl
    where cpl.caregiver_id = auth.uid()
      and cpl.status = 'active'
      and cpl.patient_id = split_part(name, '/', 1)::uuid
  )
);
