import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Wraps Firebase Cloud Messaging registration. Every call is guarded with
/// try/catch so the app behaves exactly as before when Firebase hasn't been
/// configured yet (no `google-services.json` / `GoogleService-Info.plist`) -
/// see `supabase/PUSH_KURULUM.md` for the one-time setup steps only doable
/// from the Firebase/Apple consoles.
class PushService {
  bool _initialized = false;
  String? _token;
  String? get token => _token;

  /// Initializes Firebase, requests notification permission, fetches the FCM
  /// registration token (calling [onToken] with it, and again on refresh),
  /// and listens for foreground pushes (calling [onMessage] with the
  /// notification's title/body so it can be shown via [NotificationService]).
  Future<void> init({
    required void Function(String token) onToken,
    required void Function(String title, String body) onMessage,
  }) async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;

      await FirebaseMessaging.instance.requestPermission();

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _token = token;
        onToken(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _token = newToken;
        onToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null) {
          onMessage(notification.title ?? '', notification.body ?? '');
        }
      });
    } catch (_) {
      // Firebase not configured yet (or unsupported platform/emulator) -
      // push notifications stay disabled, the rest of the app is unaffected.
    }
  }
}
