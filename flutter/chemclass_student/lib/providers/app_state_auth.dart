part of 'app_state.dart';

/// Login / logout — mirrors the planned `student_login` RPC flow: class
/// code + school number, no Supabase Auth session.
extension AppStateAuth on AppState {
  /// Returns an error message, or `null` on success.
  Future<String?> login(String code, String no) async {
    final c = code.trim();
    final n = no.trim();
    if (c.isEmpty || n.isEmpty) return 'Sınıf kodu ve okul numaranı gir.';

    loading = true;
    notify();
    try {
      final result = await _api.studentLogin(c, n);
      session = StudentSession.fromJson(result);
      await _storage.saveSession(session!);
      _seenInitialized = false;
      await refresh();
      startPolling();
      return null;
    } catch (e) {
      return _loginError(e);
    } finally {
      loading = false;
      notify();
    }
  }

  String _loginError(Object e) {
    final msg = e.toString();
    if (msg.contains('INVALID_CODE')) return 'Sınıf kodu bulunamadı. Kodu kontrol edip tekrar dene.';
    if (msg.contains('INVALID_NUMBER')) return 'Bu sınıfta bu okul numarasıyla kayıtlı bir öğrenci bulunamadı.';
    if (msg.contains('INVALID_INPUT')) return 'Sınıf kodu ve okul numaranı gir.';
    return 'Giriş yapılamadı. İnternet bağlantını kontrol et.';
  }

  Future<void> logout() async {
    stopPolling();
    await _storage.clearSession();
    session = null;
    studentInfo = null;
    leaderboard = [];
    assignments = [];
    messages = [];
    currentTab = AppTab.home;
    _seenInitialized = false;
    notify();
  }
}
