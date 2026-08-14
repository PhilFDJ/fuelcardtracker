-- ============================================================
-- Fuel Card Tracker — database setup
-- Paste this whole file into Supabase → SQL Editor → Run.
-- Safe to run more than once.
-- ============================================================

-- ---------- TABLES ----------

create table if not exists public.settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  vat     numeric(5,4) not null default 0.20,
  cards   jsonb        not null default '["Mine"]'::jsonb
);

create table if not exists public.rates (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  ex_vat     numeric(8,4) not null,
  unique (user_id, week_start)
);

create table if not exists public.fills (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  card            text not null default 'Mine',
  fill_date       date not null,
  litres          numeric(8,2) not null,
  forecourt       numeric(8,4),
  ex_vat_override numeric(8,4),
  location        text,
  paid            boolean not null default false,
  created_at      timestamptz not null default now()
);

create table if not exists public.charges (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  card        text not null default 'Mine',
  charge_date date,
  amount      numeric(10,2) not null,
  note        text,
  paid        boolean not null default false
);

create index if not exists fills_user_date_idx   on public.fills   (user_id, fill_date desc);
create index if not exists rates_user_week_idx   on public.rates   (user_id, week_start desc);
create index if not exists charges_user_idx      on public.charges (user_id);

-- ---------- ROW LEVEL SECURITY ----------
-- This is the part that keeps one user's data away from another's.
-- Without it, every signed-in user can read every row in these tables.

alter table public.settings enable row level security;
alter table public.rates    enable row level security;
alter table public.fills    enable row level security;
alter table public.charges  enable row level security;

drop policy if exists own_settings on public.settings;
create policy own_settings on public.settings
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists own_rates on public.rates;
create policy own_rates on public.rates
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists own_fills on public.fills;
create policy own_fills on public.fills
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists own_charges on public.charges;
create policy own_charges on public.charges
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- NEW USER GETS A SETTINGS ROW ----------

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- LET A USER DELETE THEIR OWN ACCOUNT ----------
-- Required so people can remove their data themselves.
-- Cascades wipe their rates, fills, charges and settings.

create or replace function public.delete_own_account()
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- ---------- CHECK IT WORKED ----------
-- Every row below must say rls_enabled = true.

select tablename, rowsecurity as rls_enabled
from pg_tables
where schemaname = 'public'
  and tablename in ('settings','rates','fills','charges')
order by tablename;
