-- current_stage는 선수 마스터가 아닌 유저별 영입 데이터로 관리
alter table public.players
  drop column if exists current_stage;
