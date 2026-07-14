-- 유저 구단 보유 선수 + 편성 역할(PK/FK/CK/Cap)

create table if not exists public.club_players (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.game_clubs(id) on delete cascade,
  player_id text not null references public.players(id),
  position_index int not null check (position_index between 1 and 21),
  acquired_at timestamptz not null default now(),
  current_stage int not null default 1 check (current_stage between 1 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint club_players_club_player_unique unique (club_id, player_id),
  constraint club_players_club_position_unique unique (club_id, position_index)
);

create index if not exists club_players_club_id_idx on public.club_players(club_id);
create index if not exists club_players_player_id_idx on public.club_players(player_id);

drop trigger if exists club_players_set_updated_at on public.club_players;
create trigger club_players_set_updated_at
before update on public.club_players
for each row
execute function public.set_game_updated_at();

alter table public.game_rosters
  add column if not exists pk_player_id text references public.players(id),
  add column if not exists fk_player_id text references public.players(id),
  add column if not exists ck_player_id text references public.players(id),
  add column if not exists captain_player_id text references public.players(id);

-- 기존 편성 → club_players 백필 (선발 1~11, 후보 12~21)
insert into public.club_players (club_id, player_id, position_index, acquired_at, current_stage)
select
  r.club_id,
  starter_id,
  ordinality::int,
  coalesce(r.created_at, now()),
  1
from public.game_rosters r
cross join lateral unnest(r.starter_player_ids) with ordinality as s(starter_id, ordinality)
where array_length(r.starter_player_ids, 1) = 11
on conflict (club_id, player_id) do nothing;

insert into public.club_players (club_id, player_id, position_index, acquired_at, current_stage)
select
  r.club_id,
  bench_id,
  (11 + ordinality)::int,
  coalesce(r.created_at, now()),
  1
from public.game_rosters r
cross join lateral unnest(r.bench_player_ids) with ordinality as b(bench_id, ordinality)
where array_length(r.bench_player_ids, 1) = 10
on conflict (club_id, player_id) do nothing;

-- 선발 중 leadership 최고를 Cap 기본값 (아직 null인 경우만)
update public.game_rosters r
set captain_player_id = sub.player_id
from (
  select
    cp.club_id,
    cp.player_id,
    row_number() over (
      partition by cp.club_id
      order by p.leadership desc nulls last, cp.position_index
    ) as rn
  from public.club_players cp
  join public.players p on p.id = cp.player_id
  where cp.position_index between 1 and 11
) sub
where r.club_id = sub.club_id
  and sub.rn = 1
  and r.captain_player_id is null;

alter table public.club_players enable row level security;

drop policy if exists "club_players_select_anon" on public.club_players;
create policy "club_players_select_anon"
on public.club_players
for select
to anon, authenticated
using (true);

drop policy if exists "club_players_insert_anon" on public.club_players;
create policy "club_players_insert_anon"
on public.club_players
for insert
to anon, authenticated
with check (true);

drop policy if exists "club_players_update_anon" on public.club_players;
create policy "club_players_update_anon"
on public.club_players
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "club_players_delete_anon" on public.club_players;
create policy "club_players_delete_anon"
on public.club_players
for delete
to anon, authenticated
using (true);

comment on table public.club_players is '구단별 보유 선수. position_index 1~11 선발, 12~21 후보';
comment on column public.club_players.position_index is '1~11 선발, 12~21 후보';
comment on column public.club_players.acquired_at is '영입 일시';
comment on column public.club_players.current_stage is '유저별 성장 기수 1~10';
comment on column public.game_rosters.pk_player_id is 'PK 키커';
comment on column public.game_rosters.fk_player_id is 'FK 키커';
comment on column public.game_rosters.ck_player_id is 'CK 키커';
comment on column public.game_rosters.captain_player_id is '주장';
