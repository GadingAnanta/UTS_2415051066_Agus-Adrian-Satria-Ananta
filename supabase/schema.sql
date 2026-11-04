-- ============================================================
-- Bengkel Digital - skema database UTS (Supabase / PostgreSQL)
-- ============================================================
-- Cara pakai:
--   1. Buka Supabase Dashboard > SQL Editor > New query
--   2. Tempel seluruh isi file ini, lalu klik "Run"
--   3. Cek di Table Editor: tabel vehicles & service_records sudah ada
--
-- Catatan keamanan:
--   - Aplikasi hanya memakai anon key, TIDAK PERNAH service_role key.
--   - RLS diaktifkan; policy di bawah mengizinkan role "anon" melakukan CRUD.
--     Ini cukup untuk tugas (belum ada login), dan bisa diperketat menjadi
--     `auth.uid() = user_id` ketika fitur autentikasi ditambahkan.
-- ============================================================

-- ------------------------------------------------------------
-- Tabel 1: vehicles
-- ------------------------------------------------------------
create table if not exists public.vehicles (
  id            bigint generated always as identity primary key,
  user_id       uuid        not null,
  brand         text        not null,
  model         text        not null,
  year          integer     not null,
  plate         text        not null,
  current_km    integer     not null default 0,
  -- Dua kolom tambahan untuk fitur pengingat pajak & STNK.
  tax_due_date  date,
  stnk_due_date date,
  created_at    timestamptz not null default now()
);

comment on table public.vehicles is 'Data sepeda motor milik pengguna';

-- ------------------------------------------------------------
-- Tabel 2: service_records (relasi 1 : banyak ke vehicles)
-- ------------------------------------------------------------
create table if not exists public.service_records (
  id           bigint generated always as identity primary key,
  vehicle_id   bigint      not null
                 references public.vehicles (id) on delete cascade,
  component    text        not null,
  service_km   integer     not null,
  cost         integer     not null,
  workshop     text,
  note         text,
  service_date date        not null,
  created_at   timestamptz not null default now()
);

comment on table public.service_records is 'Riwayat servis tiap kendaraan';

-- ------------------------------------------------------------
-- Index untuk query yang sering dipakai aplikasi
-- ------------------------------------------------------------
create index if not exists idx_service_records_vehicle
  on public.service_records (vehicle_id);
create index if not exists idx_service_records_date
  on public.service_records (service_date desc);
create index if not exists idx_vehicles_user
  on public.vehicles (user_id);

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------
alter table public.vehicles        enable row level security;
alter table public.service_records enable row level security;

-- Policy sederhana: anon key boleh CRUD (belum ada autentikasi).
drop policy if exists "anon_all_vehicles" on public.vehicles;
create policy "anon_all_vehicles" on public.vehicles
  for all
  to anon
  using (true)
  with check (true);

drop policy if exists "anon_all_service_records" on public.service_records;
create policy "anon_all_service_records" on public.service_records
  for all
  to anon
  using (true)
  with check (true);

-- ------------------------------------------------------------
-- Hak akses (GRANT) untuk role anon
-- ------------------------------------------------------------
-- RLS hanya membatasi BARIS. Role anon juga harus punya izin pada
-- tabel & sequence-nya, karena tabel yang dibuat lewat SQL Editor
-- dimiliki oleh `postgres` (bukan lewat Table Editor yang otomatis
-- memberi grant). Tanpa blok ini muncul error:
--   42501 permission denied for table vehicles
grant usage on schema public to anon;

grant select, insert, update, delete on public.vehicles        to anon;
grant select, insert, update, delete on public.service_records to anon;

-- Kolom `id` memakai identity (sequence), jadi insert butuh akses sequence.
grant usage, select on all sequences in schema public to anon;

-- ------------------------------------------------------------
-- Data contoh (opsional, boleh dihapus)
-- user_id harus sama dengan DEMO_USER_ID pada file .env
-- ------------------------------------------------------------
insert into public.vehicles (user_id, brand, model, year, plate, current_km)
values ('11111111-1111-4111-8111-111111111111', 'Honda', 'Vario 160', 2023, 'B 1234 XYZ', 12500)
on conflict do nothing;
