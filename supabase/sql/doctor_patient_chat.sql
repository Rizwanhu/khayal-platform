-- Paid patient ↔ doctor chat + Stripe subscription tracking.
-- Run in Supabase SQL Editor after profiles and doctor_patient_links exist.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- Patient chat subscription (patient pays; doctor is free) ----------
create table if not exists public.patient_chat_subscriptions (
  patient_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'inactive'
    check (status in ('inactive', 'active', 'past_due', 'canceled')),
  stripe_customer_id text,
  stripe_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_patient_chat_subscriptions_updated_at on public.patient_chat_subscriptions;
create trigger trg_patient_chat_subscriptions_updated_at
before update on public.patient_chat_subscriptions
for each row execute function public.set_updated_at();

create or replace function public.is_patient_chat_subscribed(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.patient_chat_subscriptions s
    where s.patient_id = p_patient_id
      and s.status = 'active'
      and (s.current_period_end is null or s.current_period_end > now())
  );
$$;

-- ---------- Chat threads (one per doctor + patient pair) ----------
create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (doctor_id, patient_id)
);

create index if not exists idx_chat_threads_patient on public.chat_threads(patient_id);
create index if not exists idx_chat_threads_doctor on public.chat_threads(doctor_id);

-- ---------- Messages ----------
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_thread_created
  on public.chat_messages(thread_id, created_at);

-- ---------- RLS ----------
alter table public.patient_chat_subscriptions enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists pcs_select_own on public.patient_chat_subscriptions;
create policy pcs_select_own
on public.patient_chat_subscriptions for select
to authenticated
using (patient_id = auth.uid());

drop policy if exists ct_select_participant on public.chat_threads;
create policy ct_select_participant
on public.chat_threads for select
to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists ct_insert_patient_subscribed on public.chat_threads;
create policy ct_insert_patient_subscribed
on public.chat_threads for insert
to authenticated
with check (
  patient_id = auth.uid()
  and public.is_patient_chat_subscribed(auth.uid())
  and exists (
    select 1 from public.doctor_patient_links dpl
    where dpl.doctor_id = doctor_id
      and dpl.patient_id = patient_id
      and dpl.status = 'active'
  )
);

drop policy if exists ct_insert_doctor on public.chat_threads;
create policy ct_insert_doctor
on public.chat_threads for insert
to authenticated
with check (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.doctor_patient_links dpl
    where dpl.doctor_id = doctor_id
      and dpl.patient_id = patient_id
      and dpl.status = 'active'
  )
);

drop policy if exists cm_select_participant on public.chat_messages;
create policy cm_select_participant
on public.chat_messages for select
to authenticated
using (
  exists (
    select 1 from public.chat_threads t
    where t.id = thread_id
      and (t.doctor_id = auth.uid() or t.patient_id = auth.uid())
  )
);

drop policy if exists cm_insert_participant on public.chat_messages;
create policy cm_insert_participant
on public.chat_messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.chat_threads t
    where t.id = thread_id
      and (t.doctor_id = auth.uid() or t.patient_id = auth.uid())
  )
  and (
    exists (
      select 1 from public.chat_threads t
      where t.id = thread_id and t.doctor_id = auth.uid()
    )
    or public.is_patient_chat_subscribed(auth.uid())
  )
);

-- Enable Realtime: Dashboard → Database → Replication → supabase_realtime → chat_messages
