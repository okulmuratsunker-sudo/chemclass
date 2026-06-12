part of 'app_state.dart';

/// Supabase cloud sync (`chemclass_data`) and auth - mirrors
/// `initSupabase()` / `signUp()` / `signIn()` / `signOut()` /
/// `saveToCloudNow()` / `loadFromCloud()` / `scheduleCloudSave()` /
/// `renderCloud()`.
extension AppStateCloud on AppState {
  Future<void> _initCloud() async {
    final settings = await _storage.getCloudSettings();
    if (settings != null && settings['url']!.isNotEmpty && settings['key']!.isNotEmpty) {
      sbUrl = settings['url']!;
      sbKey = settings['key']!;
      await cloud.reinit(sbUrl, sbKey);
    }
    cloudPending = await _storage.getPending();
    sbUser = await cloud.getSession();
    if (sbUser != null) {
      await loadFromCloud();
      setupTeacherRealtime();
    }
    notify();
  }

  /// Mirrors `renderCloud()`'s status text.
  String get cloudStatusText {
    if (sbUser != null && cloudPending) return '🔄 Sync bekliyor';
    if (sbUser != null) return '☁️ Bulut aktif';
    return 'Giriş yok';
  }

  String get cloudInfoText => sbUser != null
      ? 'Giriş yapıldı: ${sbUser!.email ?? ''}'
      : 'Giriş yapılmadı. Veriler sadece giriş yaptıktan sonra buluttan yüklenir.';

  Future<void> saveCloudSettings(String url, String key) async {
    sbUrl = url.trim();
    sbKey = key.trim();
    await _storage.setCloudSettings(sbUrl, sbKey);
    await cloud.reinit(
      sbUrl.isNotEmpty ? sbUrl : defaultSupabaseUrl,
      sbKey.isNotEmpty ? sbKey : defaultSupabaseAnonKey,
    );
    toast('Bulut ayarları kaydedildi');
    notify();
  }

  /// Returns an error message, or `null` on success.
  Future<String?> signUp(String email, String password) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) return 'E-posta ve şifre girin';
    try {
      final res = await cloud.signUp(e, password);
      sbUser = res.user;
      notify();
      toast('Hesap oluşturuldu. E-posta onayı gerekebilir.');
      return null;
    } catch (err) {
      return err.toString();
    }
  }

  /// Returns an error message, or `null` on success.
  Future<String?> signIn(String email, String password) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) return 'E-posta ve şifre girin';
    try {
      final res = await cloud.signIn(e, password);
      sbUser = res.user;
      notify();
      await loadFromCloud();
      setupTeacherRealtime();
      unawaited(_syncPushToken());
      toast('Giriş yapıldı ✓');
      return null;
    } catch (err) {
      return err.toString();
    }
  }

  Future<void> signOut() async {
    unawaited(_unregisterPushToken());
    try {
      await cloud.signOut();
    } catch (_) {}
    sbUser = null;
    if (_teacherMsgChannel != null) {
      cloud.removeChannel(_teacherMsgChannel!);
      _teacherMsgChannel = null;
    }
    await _storage.clearData();
    await _storage.setPending(false);
    _data = AppData.empty();
    cloudPending = false;
    teacherAssignments = [];
    teacherMessages = [];
    toast('Çıkış yapıldı. Veriler temizlendi.');
    notify();
  }

  void scheduleCloudSave() {
    if (sbUser == null) {
      cloudPending = true;
      _storage.setPending(true);
      return;
    }
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = Timer(const Duration(milliseconds: 900), saveToCloudNow);
  }

  Future<void> saveToCloudNow() async {
    if (sbUser == null) {
      cloudPending = true;
      await _storage.setPending(true);
      notify();
      return;
    }
    try {
      await cloud.upsertAppData(sbUser!.id, data.toJson());
      cloudPending = false;
      await _storage.setPending(false);
      notify();
      toast('Buluta kaydedildi ✓');
    } catch (e) {
      cloudPending = true;
      await _storage.setPending(true);
      notify();
      toast('Bulut kayıt hatası: $e');
    }
  }

  Future<void> loadFromCloud() async {
    if (sbUser == null) {
      sbUser = await cloud.getSession();
      if (sbUser == null) {
        toast('Buluttan yüklemek için giriş yapın');
        return;
      }
    }
    try {
      final row = await cloud.fetchAppData(sbUser!.id);
      if (row != null && row['app_data'] != null) {
        final cloudTime = DateTime.parse(row['updated_at'] as String).millisecondsSinceEpoch;
        final localTime = data.modified;
        if (localTime > cloudTime) {
          await saveToCloudNow();
          toast('Yerel veri buluta aktarıldı ✓');
        } else {
          _data = AppData.fromJson(row['app_data'] as Map<String, dynamic>);
          _data.modified = cloudTime;
          await _storage.saveData(_data);
          notify();
          toast('Buluttan yüklendi ✓');
        }
      } else {
        await saveToCloudNow();
        toast('Bulutta kayıt yoktu, mevcut veri kaydedildi');
      }
    } catch (e) {
      toast('Bulut okuma hatası: $e');
    }
  }
}
