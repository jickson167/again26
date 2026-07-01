-- 현재나이(age_stage) / 전성기나이 참고(peak_age)
-- 현재기(1~10)는 유저 영입 후 별도 저장 예정

alter table public.players
  add column if not exists peak_age integer;

comment on column public.players.age_stage is '현재나이 (게임 표시용)';
comment on column public.players.peak_age is '전성기 나이 참고값 (성장곡선 최고 기수에서 역산)';
