part of 'app_state.dart';

/// FCM push notification registration - best-effort and additive. If
/// Firebase hasn't been configured yet, [PushService.init] simply does
/// nothing and the app behaves exactly as before (see
/// `supabase/PUSH_KURULUM.md`).
extension AppStatePush on AppState {
  Future<void> _initPush() async {
    await pushService.init(
      onToken: (token) {
        _pushToken = token;
        unawaited(_syncPushToken());
      },
      onMessage: (title, body) => unawaited(notificationService.show(title, body)),
    );
  }

  Future<void> _syncPushToken() async {
    final token = _pushToken;
    if (token == null || sbUser == null) return;
    try {
      await cloud.registerPushToken(token);
    } catch (_) {}
  }

  Future<void> _unregisterPushToken() async {
    final token = _pushToken;
    if (token == null) return;
    try {
      await cloud.unregisterPushToken(token);
    } catch (_) {}
  }
}
