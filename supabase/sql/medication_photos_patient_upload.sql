-- Patient can upload pill photos for their own folder (run after medication_photos_storage.sql)

drop policy if exists "med_photos_insert_patient" on storage.objects;
create policy "med_photos_insert_patient"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'medication-photos'
  and split_part(name, '/', 1)::uuid = auth.uid()
);

drop policy if exists "med_photos_update_patient" on storage.objects;
create policy "med_photos_update_patient"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'medication-photos'
  and split_part(name, '/', 1)::uuid = auth.uid()
)
with check (
  bucket_id = 'medication-photos'
  and split_part(name, '/', 1)::uuid = auth.uid()
);

drop policy if exists "med_photos_delete_patient" on storage.objects;
create policy "med_photos_delete_patient"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'medication-photos'
  and split_part(name, '/', 1)::uuid = auth.uid()
);
