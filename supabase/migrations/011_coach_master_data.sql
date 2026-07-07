create table if not exists public.coach_abilities (
  id text primary key,
  name text not null,
  base_effect text not null,
  rank_effects jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coach_styles (
  id text primary key,
  name text not null unique,
  description text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.coach_abilities (id, name, base_effect, rank_effects)
values
  (
    'iron_discipline',
    '철의 규율',
    '수비 조직력↑, 라인 유지력↑',
    '{"1":"수비조직+2|라인유지+1","2":"수비조직+3|라인유지+2","3":"수비조직+4|라인유지+3","4":"수비조직+6|라인유지+4","5":"수비조직+8|라인유지+5"}'
  ),
  (
    'gegen_press',
    '게겐프레싱',
    '전방 압박 성공률↑, 세컨드볼 획득률↑',
    '{"1":"전방압박+2|세컨드볼+1","2":"전방압박+3|세컨드볼+2","3":"전방압박+5|세컨드볼+3","4":"전방압박+7|세컨드볼+4","5":"전방압박+9|세컨드볼+6"}'
  ),
  (
    'tiki_taka',
    '티키타카',
    '패스 성공률↑, 점유율↑',
    '{"1":"패스성공+2|점유율+1","2":"패스성공+3|점유율+2","3":"패스성공+5|점유율+3","4":"패스성공+7|점유율+4","5":"패스성공+9|점유율+6"}'
  ),
  (
    'fast_counter',
    '초고속 역습',
    '역습 전개속도↑, 침투 타이밍↑',
    '{"1":"역습속도+2|침투타이밍+1","2":"역습속도+3|침투타이밍+2","3":"역습속도+5|침투타이밍+3","4":"역습속도+7|침투타이밍+4","5":"역습속도+9|침투타이밍+6"}'
  ),
  (
    'wide_attack',
    '측면 공략',
    '크로스 정확도↑, 윙어 움직임↑',
    '{"1":"크로스+2|윙어움직임+1","2":"크로스+3|윙어움직임+2","3":"크로스+5|윙어움직임+3","4":"크로스+7|윙어움직임+4","5":"크로스+9|윙어움직임+6"}'
  ),
  (
    'central_break',
    '중앙 침투',
    '중앙 패스 성공률↑, 침투 패턴↑',
    '{"1":"중앙패스+2|침투패턴+1","2":"중앙패스+3|침투패턴+2","3":"중앙패스+5|침투패턴+3","4":"중앙패스+7|침투패턴+4","5":"중앙패스+9|침투패턴+6"}'
  ),
  (
    'setpiece_master',
    '세트피스 마스터',
    '코너킥·프리킥 득점 확률↑',
    '{"1":"세트피스득점+2","2":"세트피스득점+3","3":"세트피스득점+5","4":"세트피스득점+7","5":"세트피스득점+9"}'
  ),
  (
    'flexible_tactics',
    '전술 전환',
    '경기 중 포메이션 적응력↑, 전술 변화 효율↑',
    '{"1":"포메이션적응+2|전술변화+1","2":"포메이션적응+3|전술변화+2","3":"포메이션적응+5|전술변화+3","4":"포메이션적응+7|전술변화+4","5":"포메이션적응+9|전술변화+6"}'
  )
on conflict (id) do update set
  name = excluded.name,
  base_effect = excluded.base_effect,
  rank_effects = excluded.rank_effects,
  updated_at = now();

insert into public.coach_styles (id, name, description)
values
  ('balance', '밸런스형', '공수 균형이 뛰어나 어떤 포메이션에도 무난하다.'),
  ('press', '압박형', '전방 압박과 활동량을 극대화한다.'),
  ('possession', '점유형', '패스와 점유율을 바탕으로 경기를 지배한다.'),
  ('counter', '역습형', '빠른 전환과 속공에 특화되어 있다.'),
  ('defense', '수비형', '수비 조직력과 실점 억제에 강하다.'),
  ('attack', '공격형', '득점력과 공격 전개를 극대화한다.')
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  updated_at = now();

comment on table public.coach_abilities is '감독 고유능력 마스터. rank_effects는 랭크별 실제 효과 수치';
comment on table public.coach_styles is '감독 스타일 마스터';
