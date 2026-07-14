-- 선수 능력치에서 수비·골키퍼·지성감각·개인조직 제거
alter table public.players
  drop column if exists defense;

alter table public.players
  drop column if exists goalkeeper;

alter table public.players
  drop column if exists intelligence_sense;

alter table public.players
  drop column if exists individual_organization;
