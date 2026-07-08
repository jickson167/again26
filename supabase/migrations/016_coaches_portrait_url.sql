alter table public.coaches
  add column if not exists portrait_url text;

comment on column public.coaches.portrait_url is '감독 초상 URL (없으면 기본 경로 규칙 사용)';
