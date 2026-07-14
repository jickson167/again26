-- 포메이션 필드 10명 레이아웃 (슬롯 1~12 + 패널 내 6셀)
-- cell: 0 1 2 / 3 4 5 (좌→우, 위→아래)

alter table public.formations
  add column if not exists layout_outfield jsonb;

comment on column public.formations.layout_outfield is
  '필드 10명 [{slot:1-12, cell:0-5}, ...] — null이면 코드 폴백';
