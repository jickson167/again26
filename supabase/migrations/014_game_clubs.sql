create table if not exists public.game_clubs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  guest_id text,
  club_name text not null,
  club_logo_url text,
  league_tier text not null default 'second' check (league_tier in ('second', 'first', 'pro')),
  club_stats jsonb not null default '{}'::jsonb,
  player_results jsonb not null default '{}'::jsonb,
  coach_results jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint game_clubs_owner_check check (user_id is not null or guest_id is not null)
);

create table if not exists public.game_rosters (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.game_clubs(id) on delete cascade,
  formation_id text not null references public.formations(id),
  coach_id text not null references public.coaches(id),
  starter_player_ids text[] not null default '{}',
  bench_player_ids text[] not null default '{}',
  roster_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint game_rosters_starters_len check (array_length(starter_player_ids, 1) = 11),
  constraint game_rosters_bench_len check (array_length(bench_player_ids, 1) = 10)
);

create index if not exists game_clubs_user_id_idx on public.game_clubs(user_id);
create index if not exists game_clubs_guest_id_idx on public.game_clubs(guest_id);
create index if not exists game_rosters_club_id_idx on public.game_rosters(club_id);

create or replace function public.set_game_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists game_clubs_set_updated_at on public.game_clubs;
create trigger game_clubs_set_updated_at
before update on public.game_clubs
for each row
execute function public.set_game_updated_at();

drop trigger if exists game_rosters_set_updated_at on public.game_rosters;
create trigger game_rosters_set_updated_at
before update on public.game_rosters
for each row
execute function public.set_game_updated_at();

alter table public.game_clubs enable row level security;
alter table public.game_rosters enable row level security;

-- MVP: 기존 players/coaches와 동일하게 anon/authenticated CRUD 허용.
-- 운영 전에는 user_id = auth.uid() 기반 정책으로 교체.
drop policy if exists "game_clubs_select_anon" on public.game_clubs;
create policy "game_clubs_select_anon"
on public.game_clubs
for select
to anon, authenticated
using (true);

drop policy if exists "game_clubs_insert_anon" on public.game_clubs;
create policy "game_clubs_insert_anon"
on public.game_clubs
for insert
to anon, authenticated
with check (true);

drop policy if exists "game_clubs_update_anon" on public.game_clubs;
create policy "game_clubs_update_anon"
on public.game_clubs
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "game_clubs_delete_anon" on public.game_clubs;
create policy "game_clubs_delete_anon"
on public.game_clubs
for delete
to anon, authenticated
using (true);

drop policy if exists "game_rosters_select_anon" on public.game_rosters;
create policy "game_rosters_select_anon"
on public.game_rosters
for select
to anon, authenticated
using (true);

drop policy if exists "game_rosters_insert_anon" on public.game_rosters;
create policy "game_rosters_insert_anon"
on public.game_rosters
for insert
to anon, authenticated
with check (true);

drop policy if exists "game_rosters_update_anon" on public.game_rosters;
create policy "game_rosters_update_anon"
on public.game_rosters
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "game_rosters_delete_anon" on public.game_rosters;
create policy "game_rosters_delete_anon"
on public.game_rosters
for delete
to anon, authenticated
using (true);

comment on table public.game_clubs is '유저/게스트별 게임 구단 상태';
comment on table public.game_rosters is '구단의 현재 감독, 포메이션, 선발/후보 편성';
comment on column public.game_clubs.club_stats is '승점, 재정, 팬 수, 시설 등 구단 단위 확장 데이터';
comment on column public.game_clubs.player_results is '선수별 골/도움/평점/컨디션 등 결과 데이터';
comment on column public.game_clubs.coach_results is '감독별 전술 결과/승률/컵 성적 등 결과 데이터';
