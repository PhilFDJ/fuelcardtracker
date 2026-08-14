-- ============================================================
-- Fuel Card Tracker — adds the ex VAT / inc VAT display toggle
-- Paste into Supabase → SQL Editor → Run. Safe to run twice.
-- ============================================================

alter table public.settings
  add column if not exists show_inc_vat boolean not null default false;

-- Check: should list vat, cards and show_inc_vat.
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'settings'
order by ordinal_position;
