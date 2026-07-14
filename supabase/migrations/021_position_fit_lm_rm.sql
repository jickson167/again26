-- LM(slot 4) / RM(slot 6) 적정도 백필
-- CSV에는 pos_lm·pos_rm이 없었으므로 position_fit에 4·6이 비어 있거나 기본값(0/1)인 경우가 많음.
-- 기존 데이터 임시 보정:
--   pos_lm ≈ round((pos_lw + pos_cm + pos_cam) / 3)
--   pos_rm ≈ round((pos_rw + pos_cm + pos_cam) / 3)
-- DB에는 pos_cm·pos_cam이 모두 slot 5로 합쳐져 저장되므로 mid(slot 5)를 두 번 사용.
-- 결과는 1~7로 제한.

update public.players
set position_fit = position_fit || jsonb_build_object(
  '4', greatest(
    1,
    least(
      7,
      round(
        (
          coalesce((position_fit ->> '1')::numeric, 1)
          + coalesce((position_fit ->> '5')::numeric, 1)
          + coalesce((position_fit ->> '5')::numeric, 1)
        ) / 3.0
      )::int
    )
  ),
  '6', greatest(
    1,
    least(
      7,
      round(
        (
          coalesce((position_fit ->> '3')::numeric, 1)
          + coalesce((position_fit ->> '5')::numeric, 1)
          + coalesce((position_fit ->> '5')::numeric, 1)
        ) / 3.0
      )::int
    )
  )
)
where position_fit is not null
  and (
    position_fit ->> '4' is null
    or (position_fit ->> '4')::numeric in (0, 1)
    or position_fit ->> '6' is null
    or (position_fit ->> '6')::numeric in (0, 1)
  );

comment on column public.players.position_fit is
  '적정포지션 1~13 (1=LW … 4=LM … 6=RM … 13=GK), 각 1~10';
