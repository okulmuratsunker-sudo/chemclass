-- ChemClass push notifications — backend setup
--
-- Run this once in the Supabase SQL Editor for the project used by the
-- ChemClass apps (krqyzhmioqtfihwrblmb), AFTER student_app_setup.sql.
--
-- Stores one row per device (FCM registration token) so the `send-push`
-- Edge Function can look up which devices to notify when a new row is
-- inserted into chemclass_messages / chemclass_assignments. Every function
-- below is SECURITY DEFINER, so anon/authenticated clients never read this
-- table directly — they only register/unregister their own token.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Device token table
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.chemclass_push_tokens (
  id uuid primary key default gen_random_uuid(),
  owner_type text not null check (owner_type in ('teacher', 'student')),
  teacher_id uuid not null,
  student_id text,
  class_name text,
  fcm_token text not null unique,
  platform text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists chemclass_push_tokens_lookup_idx
  on public.chemclass_push_tokens (teacher_id, owner_type, class_name, student_id);

alter table public.chemclass_push_tokens enable row level security;
-- Intentionally no policies: only SECURITY DEFINER functions (and the
-- send-push Edge Function, via the service role key) touch this table.

-- ─────────────────────────────────────────────────────────────────────────
-- 2. register_teacher_push_token(fcm_token, platform)
--    Called by the ChemClass (teacher) app after Supabase Auth sign-in.
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.register_teacher_push_token(p_fcm_token text, p_platform text default 'android')
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if trim(p_fcm_token) = '' then
    raise exception 'INVALID_TOKEN';
  end if;

  insert into public.chemclass_push_tokens (owner_type, teacher_id, student_id, class_name, fcm_token, platform, updated_at)
  values ('teacher', auth.uid(), null, null, p_fcm_token, coalesce(p_platform, 'android'), now())
  on conflict (fcm_token) do update set
    owner_type = 'teacher',
    teacher_id = auth.uid(),
    student_id = null,
    class_name = null,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

grant execute on function public.register_teacher_push_token(text, text) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. register_student_push_token(session token, fcm_token, platform)
--    Called by the ChemClass Öğrenci (student) app after login.
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.register_student_push_token(p_token uuid, p_fcm_token text, p_platform text default 'android')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session record;
begin
  if trim(p_fcm_token) = '' then
    raise exception 'INVALID_TOKEN';
  end if;

  select * into v_session from public.chemclass_student_sessions where token = p_token;
  if v_session is null then
    raise exception 'INVALID_SESSION';
  end if;

  insert into public.chemclass_push_tokens (owner_type, teacher_id, student_id, class_name, fcm_token, platform, updated_at)
  values ('student', v_session.teacher_id, v_session.student_id, v_session.class_name, p_fcm_token, coalesce(p_platform, 'android'), now())
  on conflict (fcm_token) do update set
    owner_type = 'student',
    teacher_id = v_session.teacher_id,
    student_id = v_session.student_id,
    class_name = v_session.class_name,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

grant execute on function public.register_student_push_token(uuid, text, text) to anon;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. unregister_push_token(fcm_token) — called on logout / token rotation.
--    Knowing the exact token is the only "auth" required, mirroring how
--    FCM itself treats registration tokens as bearer-style identifiers.
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.unregister_push_token(p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.chemclass_push_tokens where fcm_token = p_fcm_token;
end;
$$;

grant execute on function public.unregister_push_token(text) to anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. Database Webhooks (configure in the Supabase Dashboard, not via SQL):
--    Database → Webhooks → Create a new hook
--      - Table: chemclass_messages,    Events: Insert  → HTTP request to the
--        deployed `send-push` Edge Function
--      - Table: chemclass_assignments, Events: Insert  → same Edge Function
--    See supabase/PUSH_KURULUM.md for the full step-by-step setup.
-- ─────────────────────────────────────────────────────────────────────────
