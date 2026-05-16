-- Patient home area for nearby clinics/hospitals map (OpenStreetMap).
-- Run in Supabase SQL Editor after profiles table exists.

alter table public.profiles
  add column if not exists home_lat double precision,
  add column if not exists home_lng double precision,
  add column if not exists home_area_label text;

comment on column public.profiles.home_lat is 'Patient home latitude (WGS84)';
comment on column public.profiles.home_lng is 'Patient home longitude (WGS84)';
comment on column public.profiles.home_area_label is 'Optional label e.g. neighbourhood or city';
