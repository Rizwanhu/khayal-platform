-- Chat image attachments (camera / gallery in doctor–patient chat)
--
-- BEFORE running:
-- 1) Dashboard → Storage → New bucket: chat-images (private, max ~5 MB, image/* MIME)
-- 2) Run after doctor_patient_chat.sql
-- 3) Enable Realtime on chat_messages if not already

alter table public.chat_messages
  add column if not exists image_storage_path text;

comment on column public.chat_messages.image_storage_path is
  'Path in bucket chat-images, e.g. {thread_id}/{message_id}.jpg';

-- Allow text-only OR image (optional caption in body)
alter table public.chat_messages
  drop constraint if exists chat_messages_body_check;

alter table public.chat_messages
  add constraint chat_messages_body_or_image_check
  check (
    char_length(trim(body)) > 0
    or (image_storage_path is not null and char_length(trim(image_storage_path)) > 0)
  );

-- ---------------------------------------------------------------------------
-- Storage RLS: path layout  {thread_id}/{filename}
-- ---------------------------------------------------------------------------
drop policy if exists "chat_images_select_participant" on storage.objects;
drop policy if exists "chat_images_insert_participant" on storage.objects;
drop policy if exists "chat_images_update_participant" on storage.objects;

create policy "chat_images_select_participant"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = split_part(name, '/', 1)
      and (t.doctor_id = auth.uid() or t.patient_id = auth.uid())
  )
);

create policy "chat_images_insert_participant"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = split_part(name, '/', 1)
      and (t.doctor_id = auth.uid() or t.patient_id = auth.uid())
  )
);

create policy "chat_images_update_participant"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = split_part(name, '/', 1)
      and (t.doctor_id = auth.uid() or t.patient_id = auth.uid())
  )
);
