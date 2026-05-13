# DATABASE (Supabase / PostgreSQL)

This is the baseline database design for Khayal using Supabase.
It supports:
- Patient, Caregiver, and Doctor roles
- Caregiver/Doctor to Patient linking
- Medication management
- Dose logs/history
- Alert tracking
- Push token storage

---

## 1) Core Tables

- `profiles` -> app user profile (linked to `auth.users`)
- `caregiver_patient_links` -> caregiver access to patient
- `doctor_patient_links` -> doctor read-only access to patient
- `otp_artifacts` -> OTP generation/verification for linking
- `medications` -> medicine master record
- `medication_schedules` -> one medication can have multiple times per day
- `dose_logs` -> taken/missed/snoozed/escalated history
- `alert_events` -> caregiver alerts/escalation tracking
- `push_tokens` -> FCM/APNS token registry

---

## 2) Full SQL (Create Schema)

Run this in Supabase SQL Editor.

```sql
-- =========================
-- Khayal schema bootstrap
-- =========================

create extension if not exists pgcrypto;

-- ---------- Enums ----------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('patient', 'caregiver', 'doctor');
  end if;

  if not exists (select 1 from pg_type where typname = 'med_type') then
    create type public.med_type as enum ('tablet', 'capsule', 'syrup', 'drops', 'injection', 'other');
  end if;

  if not exists (select 1 from pg_type where typname = 'dose_status') then
    create type public.dose_status as enum ('upcoming', 'taken', 'missed', 'snoozed', 'escalated');
  end if;

  if not exists (select 1 from pg_type where typname = 'link_status') then
    create type public.link_status as enum ('active', 'revoked');
  end if;

  if not exists (select 1 from pg_type where typname = 'alert_type') then
    create type public.alert_type as enum ('first_reminder', 'second_reminder', 'caregiver_alert', 'doctor_view');
  end if;
end $$;

-- ---------- Utility trigger ----------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null,
  full_name text not null,
  phone text unique,
  language_code text not null default 'en' check (language_code in ('en', 'ur')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- ---------- Caregiver <-> Patient link ----------
create table if not exists public.caregiver_patient_links (
  id uuid primary key default gen_random_uuid(),
  caregiver_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  status public.link_status not null default 'active',
  linked_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (caregiver_id, patient_id)
);

-- ---------- Doctor <-> Patient link ----------
create table if not exists public.doctor_patient_links (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  status public.link_status not null default 'active',
  linked_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (doctor_id, patient_id)
);

-- ---------- OTP artifacts ----------
create table if not exists public.otp_artifacts (
  id uuid primary key default gen_random_uuid(),
  caregiver_id uuid references public.profiles(id) on delete cascade,
  patient_phone text not null,
  otp_hash text not null,
  attempts int not null default 0 check (attempts >= 0 and attempts <= 10),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------- Medications ----------
create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete restrict,
  urdu_name text not null,
  english_name text not null,
  dose_amount numeric(10,2) not null check (dose_amount > 0),
  dose_unit text not null default 'mg',
  medication_type public.med_type not null default 'tablet',
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_medications_updated_at on public.medications;
create trigger trg_medications_updated_at
before update on public.medications
for each row execute function public.set_updated_at();

-- ---------- Medication schedules ----------
create table if not exists public.medication_schedules (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  local_time time not null,
  -- 0=Sunday ... 6=Saturday; null means every day
  days_of_week smallint[],
  created_at timestamptz not null default now(),
  unique (medication_id, local_time)
);

-- ---------- Dose logs ----------
create table if not exists public.dose_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  schedule_id uuid references public.medication_schedules(id) on delete set null,
  scheduled_for timestamptz not null,
  status public.dose_status not null,
  confirmed_at timestamptz,
  source text not null default 'mobile_app',
  created_at timestamptz not null default now(),
  unique (patient_id, medication_id, scheduled_for)
);

-- ---------- Alert events ----------
create table if not exists public.alert_events (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  caregiver_id uuid references public.profiles(id) on delete set null,
  medication_id uuid references public.medications(id) on delete set null,
  dose_log_id uuid references public.dose_logs(id) on delete set null,
  alert_type public.alert_type not null,
  message text,
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------- Push tokens ----------
create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

drop trigger if exists trg_push_tokens_updated_at on public.push_tokens;
create trigger trg_push_tokens_updated_at
before update on public.push_tokens
for each row execute function public.set_updated_at();

-- ---------- Indexes ----------
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_caregiver_links_patient on public.caregiver_patient_links(patient_id);
create index if not exists idx_doctor_links_patient on public.doctor_patient_links(patient_id);
create index if not exists idx_medications_patient_active on public.medications(patient_id, is_active);
create index if not exists idx_med_schedules_medication on public.medication_schedules(medication_id);
create index if not exists idx_dose_logs_patient_time on public.dose_logs(patient_id, scheduled_for desc);
create index if not exists idx_alert_events_patient_time on public.alert_events(patient_id, created_at desc);
create index if not exists idx_push_tokens_user_active on public.push_tokens(user_id, is_active);
```

---

## 3) Starter RLS Policies (Recommended)

Use this after creating tables. Adjust as your auth flow evolves.

```sql
-- Enable RLS
alter table public.profiles enable row level security;
alter table public.caregiver_patient_links enable row level security;
alter table public.doctor_patient_links enable row level security;
alter table public.medications enable row level security;
alter table public.medication_schedules enable row level security;
alter table public.dose_logs enable row level security;
alter table public.alert_events enable row level security;
alter table public.push_tokens enable row level security;
alter table public.otp_artifacts enable row level security;

-- Profiles: user can read/update own profile
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles for select
using (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

-- Push tokens: own tokens only
drop policy if exists push_tokens_own_all on public.push_tokens;
create policy push_tokens_own_all
on public.push_tokens for all
using (user_id = auth.uid())
with check (user_id = auth.uid());
```

---

## 4) Notes for App Team

- Keep `auth.users` as source of authentication identity.
- `profiles.id` should always match `auth.users.id`.
- Doctor access should stay read-only for MVP.
- Add more strict RLS for `medications`, `dose_logs`, and `alerts` once API flows are finalized.
