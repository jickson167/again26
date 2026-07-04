-- 선수 시드 카테고리 (여러 개 가능 · text[])
alter table public.players
  add column if not exists seed_names text[] not null default '{}';

create index if not exists players_seed_names_gin_idx
  on public.players using gin (seed_names);

comment on column public.players.seed_names is
  '시드 카테고리 목록 (예: 일반시드, 2026 월드컵 대한민국 선발). 한 선수가 여러 시드 보유 가능.';

-- 마이그레이션 시점에 이미 등록된 1랭크 선수만 일반시드 부여 (향후 1랭크 자동 부여 아님)
update public.players
set seed_names = case
  when '일반시드' = any(seed_names) then seed_names
  else array_append(coalesce(seed_names, '{}'), '일반시드')
end
where rank = 1;
