-- 선수 id를 0001 형식 text로 사용 (uuid → text)
alter table public.players alter column id drop default;

alter table public.players
  alter column id type text using id::text;

comment on column public.players.id is '선수 코드 (예: 0001). portrait 파일명과 동일';
