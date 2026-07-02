-- 선수 v3 확장 필드

alter table public.players
  add column if not exists detail_position text;

alter table public.players
  add column if not exists comment text;

alter table public.players
  add column if not exists shooting integer not null default 0
    check (shooting between 0 and 10);

alter table public.players
  add column if not exists passing integer not null default 0
    check (passing between 0 and 10);

alter table public.players
  add column if not exists defense integer not null default 0
    check (defense between 0 and 10);

alter table public.players
  add column if not exists stamina integer not null default 0
    check (stamina between 0 and 10);

alter table public.players
  add column if not exists goalkeeper integer not null default 0
    check (goalkeeper between 0 and 10);

alter table public.players
  add column if not exists recommend_key_positions text;

comment on column public.players.detail_position is '상세 포지션 (예: LW/ST)';
comment on column public.players.comment is '선수 코멘트 (관리자 편집)';
comment on column public.players.recommend_key_positions is '추천 키포지션 (kp_id:score|...)';
