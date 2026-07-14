-- 리그: 엔트리 + 클래스 1~10 (클래스 10이 최고). 기존 second/first/pro → entry.

alter table public.game_clubs
  drop constraint if exists game_clubs_league_tier_check;

update public.game_clubs
set league_tier = 'entry'
where league_tier in ('second', 'first', 'pro')
   or league_tier is null
   or league_tier not in (
     'entry',
     'class_1', 'class_2', 'class_3', 'class_4', 'class_5',
     'class_6', 'class_7', 'class_8', 'class_9', 'class_10'
   );

alter table public.game_clubs
  alter column league_tier set default 'entry';

alter table public.game_clubs
  add constraint game_clubs_league_tier_check
  check (
    league_tier in (
      'entry',
      'class_1', 'class_2', 'class_3', 'class_4', 'class_5',
      'class_6', 'class_7', 'class_8', 'class_9', 'class_10'
    )
  );

comment on column public.game_clubs.league_tier is
  '엔트리 리그(entry) 또는 클래스 1~10(class_1..class_10). 클래스 10이 최고.';
