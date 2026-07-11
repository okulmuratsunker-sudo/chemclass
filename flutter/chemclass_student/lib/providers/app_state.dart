import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment.dart';
import '../models/chat_message.dart';
import '../models/leaderboard_entry.dart';
import '../models/schedule_entry.dart';
import '../models/student_info.dart';
import '../models/student_session.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';
import '../utils/realtime_channels.dart';

part 'app_state_auth.dart';
part 'app_state_data.dart';
part 'app_state_messages.dart';
part 'app_state_push.dart';
part 'app_state_schedule.dart';
part 'app_state_tts.dart';

/// Central application state for the ChemClass Öğrenci app: session/login,
/// polling-based "live" score/assignments/messages, and the local-only
/// "Ders Programı" schedule.
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SupabaseService _api = SupabaseService();
  final NotificationService notificationService = NotificationService();
  final PushService pushService = PushService();
  final TtsService ttsService = TtsService();
  String? _pushToken;

  bool _ready = false;
  bool get ready => _ready;

  ThemeMode themeMode = ThemeMode.dark;

  StudentSession? session;
  bool get loggedIn => session != null;

  AppTab currentTab = AppTab.home;

  bool loading = false;
  StudentInfo? studentInfo;
  List<LeaderboardEntry> leaderboard = [];
  List<Assignment> assignments = [];
  List<ChatMessage> messages = [];
  List<ScheduleEntry> schedule = [];

  Timer? _pollTimer;
  bool _seenInitialized = false;
  final List<RealtimeChannel> _realtimeChannels = [];

  /// One-shot, fire-and-forget user messages for async events (new
  /// message/assignment toasts). Screens listen via [toasts].
  final StreamController<String> _toastController = StreamController<String>.broadcast();
  Stream<String> get toasts => _toastController.stream;
  void toast(String message) => _toastController.add(message);

  Future<void> init() async {
    final theme = await _storage.getTheme();
    themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;

    schedule = await _storage.loadSchedule();

    await notificationService.init();

    session = await _storage.loadSession();
    if (session != null) {
      await refresh();
      startPolling();
      startRealtime();
    }

    _ready = true;
    notifyListeners();

    unawaited(_initPush());
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.setTheme(themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setTab(AppTab tab) {
    currentTab = tab;
    notify();
  }

  void notify() => notifyListeners();

  @override
  void dispose() {
    _pollTimer?.cancel();
    stopRealtime();
    ttsService.dispose();
    _toastController.close();
    super.dispose();
  }
}
