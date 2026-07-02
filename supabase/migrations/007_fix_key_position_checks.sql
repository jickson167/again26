-- mental_pref / team_pref 허용값 재설정 (sense 포함)

alter table public.key_positions
  drop constraint if exists key_positions_mental_pref_check;

alter table public.key_positions
  add constraint key_positions_mental_pref_check
  check (mental_pref in ('intelligence', 'sense'));

alter table public.key_positions
  drop constraint if exists key_positions_team_pref_check;

alter table public.key_positions
  add constraint key_positions_team_pref_check
  check (team_pref in ('organization', 'individual'));
