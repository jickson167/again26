create table if not exists public.coaches (
  id text primary key default ('ch_' || lower(replace(gen_random_uuid()::text, '-', ''))),
  name text not null,
  fake_name text,
  nationality text,
  rank int check (rank between 1 and 5),
  coach_type text not null default '',
  base_leadership int not null default 0 check (base_leadership between 0 and 100),
  ability_id text not null default '',
  ability_name text not null default '',
  ability_effect text not null default '',
  fit_good text[] not null default '{}',
  fit_normal text[] not null default '{}',
  fit_bad text[] not null default '{}',
  leadership_curve int[] not null default '{60,66,72,78,84,88,90,91,90,88,85,80,72,62,45,25,10,0}',
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint coaches_leadership_curve_len check (array_length(leadership_curve, 1) = 18),
  constraint coaches_leadership_curve_period_18_zero check (leadership_curve[18] = 0)
);

create index if not exists coaches_rank_idx on public.coaches(rank);
create index if not exists coaches_coach_type_idx on public.coaches(coach_type);

comment on table public.coaches is '감독 마스터 데이터';
comment on column public.coaches.rank is '1~5. 비어 있으면 앱에서 통솔력+고유능력 보너스로 계산 가능';
comment on column public.coaches.base_leadership is '기본 통솔력 0~100';
comment on column public.coaches.fit_good is '높은 적합 포메이션 id 목록';
comment on column public.coaches.fit_normal is '보통 적합 포메이션 id 목록';
comment on column public.coaches.fit_bad is '낮은 적합 포메이션 id 목록';
comment on column public.coaches.leadership_curve is '1~18기 통솔력 곡선. 18기는 0으로 바닥 처리';
