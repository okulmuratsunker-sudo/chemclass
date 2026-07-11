/// SharedPreferences keys, mirroring localStorage keys from `ders-takip.html`.
const String prefsThemeKey = 'dt_theme';
const String prefsCacheKey = 'dt_v1_cache';
const String prefsQueueKey = 'dt_v1_queue';

/// Supabase project backing the Ders Takip app (separate from the main
/// ChemClass backend).
const String supabaseUrl = 'https://bqvlgodtfbeqtvxmvtdp.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxdmxnb2R0ZmJlcXR2eG12dGRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NzEyNjcsImV4cCI6MjA5NTM0NzI2N30.BJ_A8bEyqgRA3xdN7GPtx3wMnJPwn0kVWKWdbXYDOFo';

/// Bottom navigation pages, mirroring the web app's `currentPage`.
enum DtPage { dashboard, students, sessions, reports }

const Map<DtPage, String> dtPageLabels = {
  DtPage.dashboard: '📊 Özet',
  DtPage.students: '👤 Öğrenciler',
  DtPage.sessions: '📅 Dersler',
  DtPage.reports: '📈 Rapor',
};
