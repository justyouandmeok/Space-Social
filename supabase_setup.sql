-- Pegar en Supabase → SQL Editor y ejecutar una vez.

insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "public read posts" on storage.objects;
drop policy if exists "public read avatars" on storage.objects;
drop policy if exists "public upload posts" on storage.objects;
drop policy if exists "public upload avatars" on storage.objects;

create policy "public read posts"
on storage.objects for select
using (bucket_id = 'posts');

create policy "public read avatars"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "public upload posts"
on storage.objects for insert
with check (bucket_id = 'posts');

create policy "public upload avatars"
on storage.objects for insert
with check (bucket_id = 'avatars');
