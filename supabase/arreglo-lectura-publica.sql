-- Arreglo: permite que la página pública lea los mensajes y fotos APROBADOS.
-- Ejecútalo una vez en Supabase > SQL Editor. Es seguro: solo se leen filas aprobadas (lo decide la regla RLS).
grant select (moderation_status) on public.guest_messages to anon;
grant select (status) on public.guest_photos to anon;
