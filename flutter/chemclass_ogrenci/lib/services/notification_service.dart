import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/student_session.dart';
import 'supabase_service.dart';

/// Uygulama arka plandayken/kapalıyken gelen FCM mesajları için
/// kayıtlı olması gereken üst seviye işleyici.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // iOS/Android arka plan bildirimlerini sistem otomatik gösterir,
  // burada ek bir işlem yapmaya gerek yok.
}

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Uygulama açıkken gelen bildirimi yerel bildirim olarak göster
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'messages',
            'Mesajlar',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  /// Cihaz FCM token'ını alır ve Supabase'e kaydeder, ayrıca token
  /// yenilendiğinde tekrar kaydeder.
  static Future<void> registerToken(StudentSession session) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await SupabaseService.registerDeviceToken(session, token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        SupabaseService.registerDeviceToken(session, newToken);
      });
    } catch (_) {
      // Bildirim izni reddedilmiş veya FCM kullanılamıyor olabilir.
    }
  }

  /// Çıkış yapılırken bu cihazın token kaydını siler.
  static Future<void> unregisterToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await SupabaseService.removeDeviceToken(token);
      }
    } catch (_) {}
  }
}
