/// SharedPreferences keys.
const String prefsSessionKey = 'chemclass_student_session';
const String prefsThemeKey = 'cc_theme';
const String prefsScheduleKey = 'chemclass_student_schedule';
const String prefsSeenAssignmentsKey = 'chemclass_student_seen_assignments';
const String prefsSeenMessagesKey = 'chemclass_student_seen_messages';

/// Same Supabase project the teacher app + web app use.
const String supabaseUrl = 'https://krqyzhmioqtfihwrblmb.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycXl6aG1pb3F0Zmlod3JibG1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNTQzOTQsImV4cCI6MjA5NTczMDM5NH0.qE5bmGq7DksTJ4WHklpS_cGPeghkQrk5ZwjR36dn0GI';

/// How often the app polls for new score / assignment / message data while
/// running, mirroring the "live" polling used by the Tahta board viewer.
const Duration pollInterval = Duration(seconds: 10);

/// Bottom navigation tabs.
enum AppTab { home, score, assignments, messages }

const Map<AppTab, String> tabLabels = {
  AppTab.home: '🏠 Ana Sayfa',
  AppTab.score: '🏆 Puanım',
  AppTab.assignments: '📚 Ödevler',
  AppTab.messages: '💬 Mesajlar',
};

/// Days of the week for "Ders Programı" (Monday = 0 .. Sunday = 6).
const List<String> weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
