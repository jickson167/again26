-- 선수 마스터 테이블
create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  fake_name text,
  position text not null check (position in ('fw', 'mf', 'df', 'gk')),
  position_fit jsonb not null default '{}'::jsonb,
  rank integer,
  age_stage text,
  height integer,
  weight integer,
  nationality text,
  growth_type jsonb not null default '[]'::jsonb,
  speed integer not null default 0 check (speed between 0 and 10),
  power integer not null default 0 check (power between 0 and 10),
  technique integer not null default 0 check (technique between 0 and 10),
  pk_ability integer not null default 0 check (pk_ability between 0 and 10),
  fk_ability integer not null default 0 check (fk_ability between 0 and 10),
  ck_ability integer not null default 0 check (ck_ability between 0 and 10),
  leadership integer not null default 0 check (leadership between 0 and 10),
  intelligence_sense integer not null default 5 check (intelligence_sense between 0 and 10),
  individual_organization integer not null default 5 check (individual_organization between 0 and 10),
  portrait_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists players_name_idx on public.players (name);
create index if not exists players_position_idx on public.players (position);
create index if not exists players_rank_idx on public.players (rank);

create or replace function public.set_players_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists players_set_updated_at on public.players;
create trigger players_set_updated_at
before update on public.players
for each row
execute function public.set_players_updated_at();

alter table public.players enable row level security;

-- MVP: anon 키로 읽기/쓰기 허용 (운영 시 인증 기반 정책으로 교체 권장)
drop policy if exists "players_select_anon" on public.players;
create policy "players_select_anon"
on public.players
for select
to anon, authenticated
using (true);

drop policy if exists "players_insert_anon" on public.players;
create policy "players_insert_anon"
on public.players
for insert
to anon, authenticated
with check (true);

drop policy if exists "players_update_anon" on public.players;
create policy "players_update_anon"
on public.players
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "players_delete_anon" on public.players;
create policy "players_delete_anon"
on public.players
for delete
to anon, authenticated
using (true);

comment on table public.players is '축구 매니저 선수 마스터';
comment on column public.players.position_fit is '적정포지션 1~13, 각 0~10';
comment on column public.players.growth_type is '1기~10기 성장 데이터 [{speed, power, technique}]';
comment on column public.players.intelligence_sense is '0=지력10, 10=감각10';
comment on column public.players.individual_organization is '0=개인10, 10=조직10';
