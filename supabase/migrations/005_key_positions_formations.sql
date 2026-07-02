-- 키포지션 / 포메이션 마스터

create table if not exists public.key_positions (
  id text primary key,
  name text not null,
  simple_position text not null check (simple_position in ('fw', 'mf', 'df', 'gk')),
  main_stat text not null,
  sub_stat text not null,
  mental_pref text not null check (mental_pref in ('intelligence', 'sense')),
  team_pref text not null check (team_pref in ('organization', 'individual')),
  description text,
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.formations (
  id text primary key,
  name text not null,
  tactical_type text,
  key_pos_1 text,
  key_pos_2 text,
  key_pos_3 text,
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists key_positions_simple_position_idx
  on public.key_positions (simple_position);
create index if not exists formations_name_idx on public.formations (name);

create or replace function public.set_key_positions_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

create or replace function public.set_formations_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists key_positions_set_updated_at on public.key_positions;
create trigger key_positions_set_updated_at
before update on public.key_positions
for each row execute function public.set_key_positions_updated_at();

drop trigger if exists formations_set_updated_at on public.formations;
create trigger formations_set_updated_at
before update on public.formations
for each row execute function public.set_formations_updated_at();

alter table public.key_positions enable row level security;
alter table public.formations enable row level security;

drop policy if exists "key_positions_select_anon" on public.key_positions;
create policy "key_positions_select_anon" on public.key_positions
for select to anon, authenticated using (true);

drop policy if exists "key_positions_insert_anon" on public.key_positions;
create policy "key_positions_insert_anon" on public.key_positions
for insert to anon, authenticated with check (true);

drop policy if exists "key_positions_update_anon" on public.key_positions;
create policy "key_positions_update_anon" on public.key_positions
for update to anon, authenticated using (true) with check (true);

drop policy if exists "key_positions_delete_anon" on public.key_positions;
create policy "key_positions_delete_anon" on public.key_positions
for delete to anon, authenticated using (true);

drop policy if exists "formations_select_anon" on public.formations;
create policy "formations_select_anon" on public.formations
for select to anon, authenticated using (true);

drop policy if exists "formations_insert_anon" on public.formations;
create policy "formations_insert_anon" on public.formations
for insert to anon, authenticated with check (true);

drop policy if exists "formations_update_anon" on public.formations;
create policy "formations_update_anon" on public.formations
for update to anon, authenticated using (true) with check (true);

drop policy if exists "formations_delete_anon" on public.formations;
create policy "formations_delete_anon" on public.formations
for delete to anon, authenticated using (true);

comment on table public.key_positions is '키포지션(역할) 마스터';
comment on table public.formations is '포메이션 마스터';
