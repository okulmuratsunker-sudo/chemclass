/// SharedPreferences keys, mirroring localStorage keys from the web app.
const String prefsDataKey = 'chemclass_v18_data';
const String prefsLegacyDataKey = 'chemclass_v17_data';
const String prefsCloudSettingsKey = 'chemclass_v15_cloud_settings';
const String prefsThemeKey = 'cc_theme';
const String prefsSoundKey = 'cc_snd';
const String prefsPendingKey = 'cc_pending';

/// Default (configurable) Supabase project used for the main `chemclass_data`
/// sync, board sessions, assignments, messages, etc.
const String defaultSupabaseUrl = 'https://krqyzhmioqtfihwrblmb.supabase.co';
const String defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycXl6aG1pb3F0Zmlod3JibG1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNTQzOTQsImV4cCI6MjA5NTczMDM5NH0.qE5bmGq7DksTJ4WHklpS_cGPeghkQrk5ZwjR36dn0GI';

/// Hardcoded "Öğretmenim" project used purely for cross-app score sync.
const String teacherSyncUrl = 'https://yqyrhuednyhirgcghexe.supabase.co';
const String teacherSyncAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxeXJodWVkbnloaXJnY2doZXhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NzQ5MTgsImV4cCI6MjA5NTM1MDkxOH0.bPaF2xWNL4k4eZhhQpzYpaCojqSVIYe4sqM-atpoDJM';

/// Storage bucket used for assignment file attachments.
const String filesBucket = 'chemclass-files';

/// Tab/section identifiers, matching the web app's `TAB_LABELS`.
enum AppTab {
  home,
  cloud,
  boardShare,
  pick,
  timer,
  students,
  attend,
  beh,
  groups,
  board,
  assignments,
  messages,
}

const Map<AppTab, String> tabLabels = {
  AppTab.home: 'Ana Ekran',
  AppTab.cloud: 'Bulut',
  AppTab.boardShare: 'Tahta Modu',
  AppTab.pick: 'Seçici',
  AppTab.timer: 'Sayaç',
  AppTab.students: 'Sınıflar',
  AppTab.attend: 'Yoklama',
  AppTab.beh: 'Davranış',
  AppTab.groups: 'Gruplar',
  AppTab.board: 'Tablo',
  AppTab.assignments: 'Ödevler',
  AppTab.messages: 'Mesajlar',
};

const Map<AppTab, String> tabMenuLabels = {
  AppTab.home: '🏠 Ana Ekran',
  AppTab.cloud: '☁️ Bulut',
  AppTab.boardShare: '🖥️ Tahta Modu',
  AppTab.pick: '🎲 Rastgele Seçici',
  AppTab.timer: '⏳ Geri Sayım Sayacı',
  AppTab.students: '🏫 Sınıflar',
  AppTab.attend: '📋 Yoklama',
  AppTab.beh: '⭐ Davranış',
  AppTab.groups: '👥 Gruplar',
  AppTab.board: '📊 Liderlik Tablosu',
  AppTab.assignments: '📚 Ödevler',
  AppTab.messages: '💬 Mesajlar',
};

/// Sound options for the countdown timer.
enum TimerSound { beep, chime, alarm, silent }

extension TimerSoundX on TimerSound {
  String get key => switch (this) {
        TimerSound.beep => 'beep',
        TimerSound.chime => 'chime',
        TimerSound.alarm => 'alarm',
        TimerSound.silent => 'silent',
      };

  String get label => switch (this) {
        TimerSound.beep => 'Bip',
        TimerSound.chime => 'Çan',
        TimerSound.alarm => 'Alarm',
        TimerSound.silent => 'Sessiz',
      };

  static TimerSound fromKey(String key) {
    return TimerSound.values.firstWhere(
      (e) => e.key == key,
      orElse: () => TimerSound.beep,
    );
  }
}
