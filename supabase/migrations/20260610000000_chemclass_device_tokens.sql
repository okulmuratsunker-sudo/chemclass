-- Push bildirim cihaz token'larını saklayan tablo.
-- Öğrenci uygulaması girişten sonra FCM token'ını burada saklar,
-- öğretmen mesaj gönderdiğinde send-message-push edge function bu
-- tablodaki token'lara push bildirim yollar.
create table if not exists public.chemclass_device_tokens (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null,
  student_id text,
  class_name text,
  role text not null default 'student' check (role in ('student', 'teacher')),
  token text not null,
  platform text not null default 'ios',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (token)
);

create index if not exists chemclass_device_tokens_teacher_idx
  on public.chemclass_device_tokens (teacher_id);

create index if not exists chemclass_device_tokens_student_idx
  on public.chemclass_device_tokens (teacher_id, student_id);

create index if not exists chemclass_device_tokens_class_idx
  on public.chemclass_device_tokens (teacher_id, class_name);

alter table public.chemclass_device_tokens enable row level security;

-- Uygulamalar Supabase Auth kullanmadan (anon key ile) kendi
-- token kayıtlarını ekleyip güncelleyebilmeli; bu diğer
-- chemclass_* tablolarındaki erişim modeliyle aynıdır.
drop policy if exists "chemclass_device_tokens_all" on public.chemclass_device_tokens;
create policy "chemclass_device_tokens_all"
  on public.chemclass_device_tokens
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- chemclass_messages tablosunu Realtime publication'a ekle
-- (mesajların anlık güncellenmesi için gerekli; daha önce
-- eklenmediyse ekler, eklendiyse hata vermez).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chemclass_messages'
  ) then
    alter publication supabase_realtime add table public.chemclass_messages;
  end if;
end $$;
