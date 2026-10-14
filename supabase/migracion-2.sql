-- Boda Ransel & Jhuliana — ACTUALIZACIÓN 2 (fotos de invitados + estado "rechazado" en mensajes)
-- Ejecútalo UNA vez en Supabase > SQL Editor, DESPUÉS de migracion.sql.
alter table public.guest_messages drop constraint if exists guest_messages_moderation_status_check;
alter table public.guest_messages add constraint guest_messages_moderation_status_check
  check (moderation_status in ('pending','approved','hidden','rejected'));

create table if not exists public.guest_photos (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null unique check (storage_path ~ '^pending/[0-9a-f-]{16,64}\.(jpg|png|webp)$'),
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp')),
  size_bytes integer not null check (size_bytes between 1 and 5242880),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  device_key text not null check (char_length(device_key) between 16 and 64),
  created_at timestamptz not null default now(),
  moderated_at timestamptz
);
create index if not exists photos_status_idx on public.guest_photos (status, created_at desc);
alter table public.guest_photos enable row level security;
create policy photos_admin on public.guest_photos for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy photos_public on public.guest_photos for select to anon using (status = 'approved');
revoke all on public.guest_photos from anon, authenticated;
grant select (id, storage_path, created_at) on public.guest_photos to anon;
grant select, insert, update, delete on public.guest_photos to authenticated;

create or replace function public.register_photo(p_path text, p_mime text, p_size int, p_key text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_key is null or char_length(p_key) not between 16 and 64 then raise exception 'clave invalida'; end if;
  if (select count(*) from guest_photos where device_key = p_key and created_at > now() - interval '1 day') >= 30 then raise exception 'limite'; end if;
  insert into guest_photos (storage_path, mime_type, size_bytes, device_key) values (p_path, p_mime, p_size, p_key);
end $$;
revoke all on function public.register_photo(text,text,int,text) from public;
grant execute on function public.register_photo(text,text,int,text) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('guest-photos','guest-photos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy gp_upload on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'guest-photos' and name ~ '^pending/[0-9a-f-]{16,64}\.(jpg|png|webp)$');
create policy gp_read_public on storage.objects for select to anon
  using (bucket_id = 'guest-photos' and exists (select 1 from public.guest_photos p where p.storage_path = name and p.status = 'approved'));
create policy gp_admin on storage.objects for all to authenticated
  using (bucket_id = 'guest-photos' and public.is_admin()) with check (bucket_id = 'guest-photos' and public.is_admin());
