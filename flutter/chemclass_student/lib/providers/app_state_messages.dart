part of 'app_state.dart';

/// Mesajlar — a single 1:1 chat thread with the class teacher (plus
/// class-wide / everyone broadcasts), mirroring `student_send_message`.
extension AppStateMessages on AppState {
  /// Returns an error message, or `null` on success.
  Future<String?> sendMessage(String body) async {
    if (session == null) return 'Önce giriş yap';
    final b = body.trim();
    if (b.isEmpty) return 'Mesaj yazın';
    try {
      await _api.sendMessage(session!.token, b);
    } catch (_) {
      return 'Gönderilemedi. İnternet bağlantını kontrol et.';
    }
    await refresh();
    return null;
  }
}
