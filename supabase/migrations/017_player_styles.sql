create table if not exists public.player_styles (
  id text primary key,
  category text not null check (
    category in ('base', 'forward', 'midfielder', 'defender', 'goalkeeper')
  ),
  label_ko text not null,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.players
  add column if not exists style_ids text[] not null default '{}';

create index if not exists players_style_ids_idx
  on public.players using gin (style_ids);

drop trigger if exists player_styles_set_updated_at on public.player_styles;
create trigger player_styles_set_updated_at
before update on public.player_styles
for each row
execute function public.set_simple_updated_at();

insert into public.player_styles (id, category, label_ko, sort_order) values
  ('speed', 'base', '스피드형', 1),
  ('physical', 'base', '피지컬형', 2),
  ('technical', 'base', '테크니컬형', 3),
  ('tactical', 'base', '전략형', 4),
  ('pressing', 'base', '압박형', 5),
  ('stamina', 'base', '활동량형', 6),
  ('balanced', 'base', '밸런스형', 7),
  ('leader', 'base', '리더형', 8),
  ('speed_winger', 'forward', '빠른 윙어', 1),
  ('inside_forward', 'forward', '안쪽 침투 윙어', 2),
  ('finisher', 'forward', '결정력형', 3),
  ('poacher', 'forward', '문전 침투형', 4),
  ('target_man', 'forward', '타겟맨', 5),
  ('dribbler', 'forward', '드리블러', 6),
  ('pressing_forward', 'forward', '압박형 공격수', 7),
  ('counter_attacker', 'forward', '역습형 공격수', 8),
  ('playmaker', 'midfielder', '플레이메이커', 1),
  ('creative_midfielder', 'midfielder', '창의형 미드필더', 2),
  ('tempo_controller', 'midfielder', '경기 조율형', 3),
  ('box_to_box', 'midfielder', '박스 투 박스', 4),
  ('ball_winner', 'midfielder', '볼 위닝 미드필더', 5),
  ('pressing_midfielder', 'midfielder', '압박형 미드필더', 6),
  ('deep_lying_playmaker', 'midfielder', '후방 플레이메이커', 7),
  ('setpiece', 'midfielder', '세트피스 키커', 8),
  ('build_up_cb', 'defender', '빌드업 센터백', 1),
  ('stopper', 'defender', '스토퍼', 2),
  ('cover_defender', 'defender', '커버형 수비수', 3),
  ('physical_cb', 'defender', '피지컬 센터백', 4),
  ('defensive_fullback', 'defender', '수비형 풀백', 5),
  ('attacking_fullback', 'defender', '공격형 풀백', 6),
  ('pressing_fullback', 'defender', '압박형 풀백', 7),
  ('aerial_defender', 'defender', '제공권 수비수', 8),
  ('shot_stopper', 'goalkeeper', '선방형', 1),
  ('sweeper_keeper', 'goalkeeper', '스위퍼 키퍼', 2),
  ('command_keeper', 'goalkeeper', '수비 지휘형', 3),
  ('pk_specialist', 'goalkeeper', 'PK 선방형', 4),
  ('stable_keeper', 'goalkeeper', '안정형 키퍼', 5)
on conflict (id) do nothing;

alter table public.player_styles enable row level security;

drop policy if exists "player_styles_select_anon" on public.player_styles;
create policy "player_styles_select_anon"
on public.player_styles
for select
to anon, authenticated
using (true);

drop policy if exists "player_styles_insert_anon" on public.player_styles;
create policy "player_styles_insert_anon"
on public.player_styles
for insert
to anon, authenticated
with check (true);

drop policy if exists "player_styles_update_anon" on public.player_styles;
create policy "player_styles_update_anon"
on public.player_styles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "player_styles_delete_anon" on public.player_styles;
create policy "player_styles_delete_anon"
on public.player_styles
for delete
to anon, authenticated
using (true);

comment on table public.player_styles is '선수 플레이 스타일 마스터 (기본·포지션별)';
comment on column public.players.style_ids is '선수에 부여된 스타일 id 목록 (최대 5개, 앱에서 검증)';
