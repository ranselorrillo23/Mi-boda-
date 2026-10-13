-- Boda Ransel & Jhuliana — copia y pega TODO en Supabase > SQL Editor > Run
create extension if not exists pgcrypto;

create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null check (char_length(btrim(guest_name)) between 1 and 100),
  attendance_status text not null check (attendance_status in ('attending','not_attending')),
  device_key text not null check (char_length(device_key) between 16 and 64),
  name_key text generated always as (lower(btrim(guest_name))) stored,
  invitation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (device_key, name_key)
);
create table if not exists public.guest_messages (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null check (char_length(btrim(guest_name)) between 1 and 80),
  message text not null check (char_length(btrim(message)) between 1 and 500),
  moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','hidden')),
  device_key text not null check (char_length(device_key) between 16 and 64),
  created_at timestamptz not null default now(),
  moderated_at timestamptz
);
create index if not exists msgs_status_idx on public.guest_messages (moderation_status, created_at desc);
create table if not exists public.admins (user_id uuid primary key references auth.users(id) on delete cascade);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid()) $$;

alter table public.rsvps enable row level security;
alter table public.guest_messages enable row level security;
alter table public.admins enable row level security;

-- Solo administradores: ver y gestionar todo
create policy rsvps_admin on public.rsvps for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy msgs_admin on public.guest_messages for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy admins_self on public.admins for select to authenticated using (user_id = auth.uid());
-- Visitantes: solo mensajes aprobados (y solo 4 columnas)
create policy msgs_public on public.guest_messages for select to anon using (moderation_status = 'approved');

revoke all on public.rsvps, public.guest_messages, public.admins from anon, authenticated;
grant select (id, guest_name, message, created_at) on public.guest_messages to anon;
grant select, insert, update, delete on public.rsvps, public.guest_messages to authenticated;
grant select on public.admins to authenticated;

-- Escritura de invitados (validada en el servidor)
create or replace function public.submit_rsvp(p_name text, p_status text, p_key text) returns void
language plpgsql security definer set search_path = public as $$
begin
  p_name := btrim(coalesce(p_name,''));
  if char_length(p_name) not between 1 and 100 then raise exception 'nombre invalido'; end if;
  if p_status not in ('attending','not_attending') then raise exception 'respuesta invalida'; end if;
  if p_key is null or char_length(p_key) not between 16 and 64 then raise exception 'clave invalida'; end if;
  if (select count(*) from rsvps where device_key = p_key and name_key <> lower(p_name)) >= 10 then raise exception 'limite'; end if;
  insert into rsvps (guest_name, attendance_status, device_key) values (p_name, p_status, p_key)
  on conflict (device_key, name_key) do update set attendance_status = excluded.attendance_status, guest_name = excluded.guest_name, updated_at = now();
end $$;

create or replace function public.submit_message(p_name text, p_message text, p_key text) returns void
language plpgsql security definer set search_path = public as $$
begin
  p_name := btrim(coalesce(p_name,'')); p_message := btrim(coalesce(p_message,''));
  if char_length(p_name) not between 1 and 80 then raise exception 'nombre invalido'; end if;
  if char_length(p_message) not between 1 and 500 then raise exception 'mensaje invalido'; end if;
  if p_key is null or char_length(p_key) not between 16 and 64 then raise exception 'clave invalida'; end if;
  if (select count(*) from guest_messages where device_key = p_key and created_at > now() - interval '1 hour') >= 3 then raise exception 'limite'; end if;
  insert into guest_messages (guest_name, message, device_key) values (p_name, p_message, p_key);
end $$;

revoke all on function public.submit_rsvp(text,text,text), public.submit_message(text,text,text) from public;
grant execute on function public.submit_rsvp(text,text,text), public.submit_message(text,text,text) to anon, authenticated;
