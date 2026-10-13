# Boda Ransel & Jhuliana — guía de publicación

Estructura: `index.html` (invitación), `admin.html` (panel privado), `config.js` (tus 2 datos de Supabase), `img/`, `audio/`, `supabase/migracion.sql`, `vercel.json`.

## PASO 1 — Supabase (guarda las respuestas)
1. Entra a supabase.com, crea una cuenta gratis y pulsa **New project**. Ponle un nombre y una contraseña (guárdala).
2. Menú **SQL Editor** → **New query** → pega TODO el contenido de `supabase/migracion.sql` → **Run**. Debe decir "Success".
3. Menú **Authentication → Users → Add user → Create new user**: pon TU correo y una contraseña fuerte. Marca "Auto confirm user". Esta será tu cuenta para entrar al panel.
4. Vuelve a **SQL Editor** y ejecuta esto (cambia el correo por el tuyo):
   `insert into public.admins (user_id) select id from auth.users where email = 'TU_CORREO@ejemplo.com';`
5. **Project Settings → API**: copia el **Project URL** y la **Publishable key** (empieza con `sb_publishable_` o es la "anon key").
6. Abre `config.js` y pega esos 2 datos entre las comillas. NUNCA pegues la "secret" / "service_role".

## PASO 2 — GitHub (guarda tus archivos)
1. Crea cuenta en github.com → botón **New repository** → nombre `boda-ransel-jhuliana` → **Private** → **Create repository**.
2. Pulsa **uploading an existing file**, arrastra TODO el contenido de esta carpeta (incluidas `img`, `audio` y `supabase`) y pulsa **Commit changes**.

## PASO 3 — Vercel (lo publica con un link)
1. Entra a vercel.com → **Sign up with GitHub**.
2. **Add New → Project** → elige `boda-ransel-jhuliana` → **Import**.
3. No cambies nada (Framework: Other) → **Deploy**. En ~1 minuto tendrás un link tipo `https://boda-ransel-jhuliana.vercel.app`.
4. Ese link es el que compartes por WhatsApp. Tu panel está en `https://TU-LINK.vercel.app/admin`.

## Ver las respuestas de cada invitado
Entra a `/admin` con el correo y contraseña del paso 1.3. Verás nombre, respuesta y fecha de cada invitado, totales, búsqueda, filtro, **Exportar CSV** y la pestaña **Mensajes** para **Aprobar u Ocultar** los mensajes (nada se publica sin tu aprobación).

## Para actualizar después
Cambia el archivo en GitHub (lápiz ✏️ → Commit). Vercel republica solo.

## Antes de compartir (lista rápida)
- [ ] Envía una confirmación de prueba desde tu celular y compruébala en /admin; luego bórrala en Supabase > Table Editor > rsvps.
- [ ] Escanea el QR de Yape desde otro celular.
- [ ] Confirma que suena la música y que el mapa abre la dirección.
- [ ] Reemplaza en `img/` las fotos si quieres otras (mismos nombres).

## Notas de seguridad
- La "publishable key" es pública por diseño; lo que protege tus datos son las reglas (RLS) de `migracion.sql`: los visitantes solo pueden ENVIAR respuestas y leer mensajes aprobados.
- Un mismo celular puede responder por varias personas (distintos nombres). Si una persona vuelve a enviar, se actualiza su respuesta en vez de duplicarse.
- Los nombres iguales de personas distintas en celulares distintos quedan como registros separados.
