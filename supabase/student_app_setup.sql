-- ChemClass Öğrenci (Student) app — backend setup
--
-- Run this once in the Supabase SQL Editor for the project used by the
-- ChemClass apps (krqyzhmioqtfihwrblmb). It adds everything the student app
-- needs to log in with a class code + school number (no Supabase Auth) and
-- to read/send data, WITHOUT requiring any RLS changes to the existing
-- chemclass_data / chemclass_assignments / chemclass_messages tables: every
-- function below is SECURITY DEFINER and owned by the table owner, so it can
-- read/write those tables directly while the `anon` role only ever sees the
-- narrow result the function returns.
--
-- Data shapes referenced (for context, not created here):
--   chemclass_data.app_data ->> 'classCodes'  : { "<className>": "<6-char code>" }
--   chemclass_data.app_data ->> 'students'    : [{ id, className, name, no, score, history, color }, ...]
--   chemclass_assignments   : id, teacher_id, class_name, type, title, body,
--                              due_date, file_url, file_name, file_path, created_at
--   chemclass_messages      : id, teacher_id, student_id, class_name, sender,
--                              sender_name, body, created_at, read_at

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Session table — created on `student_login`, looked up by every other
--    student RPC. Anon has no direct access to this table; only the
--    SECURITY DEFINER functions below read/write it.
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.chemclass_student_sessions (
  token uuid primary key default gen_random_uuid(),
  teacher_id uuid not null,
  student_id text not null,
  class_name text not null,
  student_no text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

alter table public.chemclass_student_sessions enable row level security;
-- Intentionally no policies: only SECURITY DEFINER functions touch this table.

-- ─────────────────────────────────────────────────────────────────────────
-- 2. student_login(code, no) -> session token + basic student info
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.student_login(p_code text, p_no text)
returns table (
  token uuid,
  student_id text,
  student_name text,
  class_name text,
  score int,
  teacher_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := upper(trim(p_code));
  v_no text := trim(p_no);
  v_teacher_id uuid;
  v_class_name text;
  v_student jsonb;
  v_token uuid;
begin
  if v_code = '' or v_no = '' then
    raise exception 'INVALID_INPUT';
  end if;

  -- Find the teacher + class whose join code matches.
  select cd.user_id, kv.key
    into v_teacher_id, v_class_name
  from public.chemclass_data cd
  cross join lateral jsonb_each_text(coalesce(cd.app_data->'classCodes', '{}'::jsonb)) as kv(key, value)
  where upper(kv.value) = v_code
  limit 1;

  if v_teacher_id is null then
    raise exception 'INVALID_CODE';
  end if;

  -- Find the student in that class with this school number.
  select s
    into v_student
  from public.chemclass_data cd2
  cross join lateral jsonb_array_elements(coalesce(cd2.app_data->'students', '[]'::jsonb)) as s
  where cd2.user_id = v_teacher_id
    and s->>'className' = v_class_name
    and trim(s->>'no') = v_no
  limit 1;

  if v_student is null then
    raise exception 'INVALID_NUMBER';
  end if;

  v_token := gen_random_uuid();
  insert into public.chemclass_student_sessions (token, teacher_id, student_id, class_name, student_no)
  values (v_token, v_teacher_id, v_student->>'id', v_class_name, v_no);

  return query select
    v_token,
    v_student->>'id',
    v_student->>'name',
    v_class_name,
    coalesce((v_student->>'score')::int, 0),
    v_teacher_id;
end;
$$;

grant execute on function public.student_login(text, text) to anon;

-- ─────────────────────────────────────────────────────────────────────────
-- 3. student_get_data(token) -> everything the home/score/assignments/
--    messages screens need, in one call (used for polling-based "live"
--    updates, same pattern as the existing Tahta board viewer).
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.student_get_data(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session record;
  v_app_data jsonb;
  v_student jsonb;
  v_leaderboard jsonb;
  v_assignments jsonb;
  v_messages jsonb;
begin
  select * into v_session from public.chemclass_student_sessions where token = p_token;
  if v_session is null then
    raise exception 'INVALID_SESSION';
  end if;

  update public.chemclass_student_sessions set last_seen_at = now() where token = p_token;

  select app_data into v_app_data from public.chemclass_data where user_id = v_session.teacher_id;
  if v_app_data is null then
    v_app_data := '{}'::jsonb;
  end if;

  -- This student's current record (score/history may have changed).
  select s into v_student
  from jsonb_array_elements(coalesce(v_app_data->'students', '[]'::jsonb)) as s
  where s->>'id' = v_session.student_id
  limit 1;

  -- Leaderboard: every student in the same class, best score first.
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', s->>'id',
           'name', s->>'name',
           'score', coalesce((s->>'score')::int, 0),
           'color', coalesce((s->>'color')::int, 0)
         ) order by coalesce((s->>'score')::int, 0) desc), '[]'::jsonb)
    into v_leaderboard
  from jsonb_array_elements(coalesce(v_app_data->'students', '[]'::jsonb)) as s
  where s->>'className' = v_session.class_name;

  -- Assignments / announcements / tasks for this student's class.
  select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at desc), '[]'::jsonb)
    into v_assignments
  from public.chemclass_assignments a
  where a.teacher_id = v_session.teacher_id
    and a.class_name = v_session.class_name;

  -- Messages: 1:1 with this student, plus class-wide / everyone broadcasts.
  select coalesce(jsonb_agg(to_jsonb(m.*) order by m.created_at asc), '[]'::jsonb)
    into v_messages
  from public.chemclass_messages m
  where m.teacher_id = v_session.teacher_id
    and (
      m.student_id = v_session.student_id
      or (m.sender = 'teacher' and m.student_id is null and m.class_name = v_session.class_name)
      or (m.sender = 'teacher' and m.student_id is null and m.class_name is null)
    );

  return jsonb_build_object(
    'student', v_student,
    'leaderboard', v_leaderboard,
    'assignments', v_assignments,
    'messages', v_messages
  );
end;
$$;

grant execute on function public.student_get_data(uuid) to anon;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. student_send_message(token, body) -> sends a reply to the teacher
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.student_send_message(p_token uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session record;
  v_app_data jsonb;
  v_student jsonb;
  v_name text;
  v_body text := trim(p_body);
begin
  if v_body = '' then
    raise exception 'EMPTY_BODY';
  end if;

  select * into v_session from public.chemclass_student_sessions where token = p_token;
  if v_session is null then
    raise exception 'INVALID_SESSION';
  end if;

  update public.chemclass_student_sessions set last_seen_at = now() where token = p_token;

  select app_data into v_app_data from public.chemclass_data where user_id = v_session.teacher_id;
  select s into v_student
  from jsonb_array_elements(coalesce(v_app_data->'students', '[]'::jsonb)) as s
  where s->>'id' = v_session.student_id
  limit 1;
  v_name := coalesce(v_student->>'name', 'Öğrenci');

  insert into public.chemclass_messages (teacher_id, student_id, class_name, sender, sender_name, body)
  values (v_session.teacher_id, v_session.student_id, v_session.class_name, 'student', v_name, v_body);
end;
$$;

grant execute on function public.student_send_message(uuid, text) to anon;
