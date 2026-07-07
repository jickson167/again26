alter table public.coaches
  add column if not exists age int;

comment on column public.coaches.age is '감독 나이';
