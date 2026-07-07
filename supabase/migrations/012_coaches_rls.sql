-- coaches / coach 마스터: players(001)와 동일하게 anon·authenticated CRUD 허용
-- RLS만 켜져 있고 정책이 없으면 INSERT 시 "violates row-level security policy" 발생

alter table public.coaches enable row level security;

drop policy if exists "coaches_select_anon" on public.coaches;
create policy "coaches_select_anon"
on public.coaches
for select
to anon, authenticated
using (true);

drop policy if exists "coaches_insert_anon" on public.coaches;
create policy "coaches_insert_anon"
on public.coaches
for insert
to anon, authenticated
with check (true);

drop policy if exists "coaches_update_anon" on public.coaches;
create policy "coaches_update_anon"
on public.coaches
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "coaches_delete_anon" on public.coaches;
create policy "coaches_delete_anon"
on public.coaches
for delete
to anon, authenticated
using (true);

alter table public.coach_abilities enable row level security;

drop policy if exists "coach_abilities_select_anon" on public.coach_abilities;
create policy "coach_abilities_select_anon"
on public.coach_abilities
for select
to anon, authenticated
using (true);

drop policy if exists "coach_abilities_insert_anon" on public.coach_abilities;
create policy "coach_abilities_insert_anon"
on public.coach_abilities
for insert
to anon, authenticated
with check (true);

drop policy if exists "coach_abilities_update_anon" on public.coach_abilities;
create policy "coach_abilities_update_anon"
on public.coach_abilities
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "coach_abilities_delete_anon" on public.coach_abilities;
create policy "coach_abilities_delete_anon"
on public.coach_abilities
for delete
to anon, authenticated
using (true);

alter table public.coach_styles enable row level security;

drop policy if exists "coach_styles_select_anon" on public.coach_styles;
create policy "coach_styles_select_anon"
on public.coach_styles
for select
to anon, authenticated
using (true);

drop policy if exists "coach_styles_insert_anon" on public.coach_styles;
create policy "coach_styles_insert_anon"
on public.coach_styles
for insert
to anon, authenticated
with check (true);

drop policy if exists "coach_styles_update_anon" on public.coach_styles;
create policy "coach_styles_update_anon"
on public.coach_styles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "coach_styles_delete_anon" on public.coach_styles;
create policy "coach_styles_delete_anon"
on public.coach_styles
for delete
to anon, authenticated
using (true);
