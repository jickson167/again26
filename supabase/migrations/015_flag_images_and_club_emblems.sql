create table if not exists public.nation_flag_images (
  nationality text primary key,
  image_data text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.club_emblems (
  id text primary key,
  grade int not null check (grade between 1 and 3),
  seed_type text not null default '일반시드',
  image_data text,
  updated_at timestamptz not null default now(),
  constraint club_emblems_id_format check (id ~ '^[0-9]{3}$')
);

create or replace function public.set_simple_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists nation_flag_images_set_updated_at on public.nation_flag_images;
create trigger nation_flag_images_set_updated_at
before update on public.nation_flag_images
for each row
execute function public.set_simple_updated_at();

drop trigger if exists club_emblems_set_updated_at on public.club_emblems;
create trigger club_emblems_set_updated_at
before update on public.club_emblems
for each row
execute function public.set_simple_updated_at();

insert into public.club_emblems (id, grade, seed_type)
select
  lpad(gs::text, 3, '0') as id,
  case
    when gs between 1 and 20 then 1
    when gs between 21 and 40 then 2
    else 3
  end as grade,
  '일반시드' as seed_type
from generate_series(1, 60) as gs
on conflict (id) do nothing;

alter table public.nation_flag_images enable row level security;
alter table public.club_emblems enable row level security;

drop policy if exists "nation_flag_images_select_anon" on public.nation_flag_images;
create policy "nation_flag_images_select_anon"
on public.nation_flag_images
for select
to anon, authenticated
using (true);

drop policy if exists "nation_flag_images_insert_anon" on public.nation_flag_images;
create policy "nation_flag_images_insert_anon"
on public.nation_flag_images
for insert
to anon, authenticated
with check (true);

drop policy if exists "nation_flag_images_update_anon" on public.nation_flag_images;
create policy "nation_flag_images_update_anon"
on public.nation_flag_images
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "nation_flag_images_delete_anon" on public.nation_flag_images;
create policy "nation_flag_images_delete_anon"
on public.nation_flag_images
for delete
to anon, authenticated
using (true);

drop policy if exists "club_emblems_select_anon" on public.club_emblems;
create policy "club_emblems_select_anon"
on public.club_emblems
for select
to anon, authenticated
using (true);

drop policy if exists "club_emblems_insert_anon" on public.club_emblems;
create policy "club_emblems_insert_anon"
on public.club_emblems
for insert
to anon, authenticated
with check (true);

drop policy if exists "club_emblems_update_anon" on public.club_emblems;
create policy "club_emblems_update_anon"
on public.club_emblems
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "club_emblems_delete_anon" on public.club_emblems;
create policy "club_emblems_delete_anon"
on public.club_emblems
for delete
to anon, authenticated
using (true);

comment on table public.nation_flag_images is '국가명별 업로드 국기 이미지(data URL)';
comment on table public.club_emblems is '클럽 앰블럼 슬롯(001~060), 등급/시드/이미지 관리';
