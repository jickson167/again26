-- 선수 시드 1개 제한 + 기존 데이터 정리

-- 1) 시드 2개 이상인 선수에서 일반시드 제거
update public.players
set seed_names = array(
  select s
  from unnest(seed_names) as s
  where s not in ('일반시드', '일반 시드')
    and trim(s) <> ''
)
where cardinality(seed_names) >= 2;

-- 2) 여전히 2개 이상이면 1개만 유지 (비일반시드 우선)
update public.players p
set seed_names = array[(
  select s
  from unnest(p.seed_names) as s
  where trim(s) <> ''
  order by
    case when s in ('일반시드', '일반 시드') then 1 else 0 end,
    s
  limit 1
)]
where cardinality(p.seed_names) > 1;

-- 3) 빈 배열 → 일반시드
update public.players
set seed_names = array['일반시드']
where cardinality(seed_names) = 0;

alter table public.players
  drop constraint if exists players_seed_names_single_chk;

alter table public.players
  add constraint players_seed_names_single_chk
  check (cardinality(seed_names) <= 1);

comment on column public.players.seed_names is
  '시드 카테고리 1개 (예: 일반시드, 2026 월드컵 대한민국). 배열 길이 최대 1.';
