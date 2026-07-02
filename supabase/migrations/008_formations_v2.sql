-- 포메이션 v2: tactical_type 제거, formation_type + 능력치 + slot 추가

alter table public.formations drop column if exists tactical_type;

alter table public.formations
  add column if not exists formation_type text
    check (formation_type in ('S', 'T', 'P'));

alter table public.formations
  add column if not exists possession int
    check (possession >= 0 and possession <= 10);

alter table public.formations
  add column if not exists attack int
    check (attack >= 0 and attack <= 10);

alter table public.formations
  add column if not exists stability int
    check (stability >= 0 and stability <= 10);

alter table public.formations
  add column if not exists key_pos_1_slot int
    check (key_pos_1_slot >= 1 and key_pos_1_slot <= 13);

alter table public.formations
  add column if not exists key_pos_2_slot int
    check (key_pos_2_slot >= 1 and key_pos_2_slot <= 13);

alter table public.formations
  add column if not exists key_pos_3_slot int
    check (key_pos_3_slot >= 1 and key_pos_3_slot <= 13);

comment on column public.formations.formation_type is 'S=Speed, T=Technique, P=Power (배지용)';
comment on column public.formations.possession is '점유율 0~10';
comment on column public.formations.attack is '공격성 0~10';
comment on column public.formations.stability is '안정성 0~10';
