# Space Social — checklist Firebase + Supabase

## Firebase
1. Authentication → Sign-in method: Email/Password ON, Google ON.
2. Authentication → Settings → User account linking: "Link accounts that use the same email".
3. Firestore Rules (Publish):

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}

4. SHA-1 release: 47:CA:BE:2C:7B:4A:01:B6:E4:D7:9B:3B:2D:EA:73:F1:87:A6:B8:0F

## Supabase (obligatorio para fotos)
SQL Editor → Run:

insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

create policy if not exists "public read posts" on storage.objects for select using (bucket_id = 'posts');
create policy if not exists "public read avatars" on storage.objects for select using (bucket_id = 'avatars');
create policy if not exists "upload posts" on storage.objects for insert with check (bucket_id = 'posts');
create policy if not exists "upload avatars" on storage.objects for insert with check (bucket_id = 'avatars');
create policy if not exists "update posts" on storage.objects for update using (bucket_id = 'posts');
create policy if not exists "update avatars" on storage.objects for update using (bucket_id = 'avatars');
