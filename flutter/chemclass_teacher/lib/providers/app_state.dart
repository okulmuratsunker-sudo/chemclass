import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_data.dart';
import '../models/assignment.dart';
import '../models/chat_message.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/teacher_sync_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/import_utils.dart';

part 'app_state_students.dart';
part 'app_state_pick.dart';
part 'app_state_groups.dart';
part 'app_state_attendance.dart';
part 'app_state_timer.dart';
part 'app_state_export.dart';
part 'app_state_cloud.dart';
part 'app_state_board.dart';
part 'app_state_assignments.dart';
part 'app_state_messages.dart';

/// Central application state, mirroring the web app's single global `data`
/// object plus all of its mutable runtime state (pick history, groups,
/// timer, board sessions, cloud sync, assignments, messages).
///
/// Split across multiple `part` files by feature area (see the `part`
/// directives above) - all parts share this class's private fields.
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SoundService soundService = SoundService();
  final NotificationService notificationService = NotificationService();
  final TeacherSyncService _teacherSync = TeacherSyncService();
  SupabaseService cloud = SupabaseService();

  AppData _data = AppData.empty();
  AppData get data => _data;

  ThemeMode themeMode = ThemeMode.dark;

  bool _ready = false;
  bool get ready => _ready;

  // ── Navigation ────────────────────────────────────────────────────────────
  AppTab currentTab = AppTab.home;

  /// Switches the active section, mirroring the web app's `tab()`.
  void setTab(AppTab tab) {
    currentTab = tab;
    if (tab == AppTab.attend) ensureAttState(selectedAttClass);
    notify();
  }

  // ── Pick (Rastgele Seçici) ────────────────────────────────────────────────
  List<String> picked = [];
  String? lastPick;
  bool isSpinning = false;
  String spinName = '?';
  String pickResultName = '?';
  String pickResultInfo = '';
  DateTime? lastPickTime;
  String selectedPickClass = '';

  // ── Groups (Gruplar) ──────────────────────────────────────────────────────
  List<StudyGroup> groups = [];
  String selectedGroupClass = '';
  String groupMode = 'count'; // 'count' | 'size'
  int groupVal = 4;

  // ── Attendance (Yoklama) ──────────────────────────────────────────────────
  String selectedAttClass = '';
  String attDate = todayStr();
  Map<String, String> attState = {};
  String attStateKey = '';

  // ── Timer (Sayaç) ─────────────────────────────────────────────────────────
  int timerTotal = 300;
  int timerLeft = 300;
  Timer? _timerHandle;
  TimerSound sndType = TimerSound.beep;
  bool get timerRunning => _timerHandle != null;

  // ── Board / Davranış / Sınıflar filters ──────────────────────────────────
  String selectedBehClass = '';
  String selectedBoardClass = '';
  String selectedImportClass = '';
  String selectedExportClass = '';
  String selectedResetClass = '';

  // ── Cloud sync ────────────────────────────────────────────────────────────
  User? sbUser;
  bool cloudPending = false;
  Timer? _cloudSaveTimer;
  String sbUrl = defaultSupabaseUrl;
  String sbKey = defaultSupabaseAnonKey;

  // ── Tahta Modu (board host) ───────────────────────────────────────────────
  String activeBoardCode = '';
  String activeBoardClass = '';
  String boardCurrentView = 'list';
  Timer? _boardUpdateTimer;
  int shareHours = 8;
  String selectedShareClass = '';

  // ── Tahta Modu (board viewer) ────────────────────────────────────────────
  bool boardViewerConnected = false;
  Map<String, dynamic>? boardViewerData;
  String boardViewerCode = '';
  Timer? _boardPollTimer;
  DateTime? boardViewerUpdatedAt;
  String boardViewerError = '';
  String boardViewerMode = 'auto'; // 'auto' | 'manual'
  String boardViewerManualView = 'list';
  String? _boardViewerLastPickTime;
  bool boardViewerSpinning = false;
  String boardViewerSpinName = '';
  Map<String, dynamic>? boardViewerPickResult;
  Timer? _boardViewerSpinTimer;

  // ── Assignments (Ödevler) ────────────────────────────────────────────────
  List<Assignment> teacherAssignments = [];
  String selectedAssignmentFilterClass = '';

  // ── Messages (Mesajlar) ──────────────────────────────────────────────────
  List<ChatMessage> teacherMessages = [];
  String? convStudentId;
  RealtimeChannel? _teacherMsgChannel;
  String selectedMessageClass = '';
  String selectedMessageScope = 'student'; // 'student' | 'class' | 'all'
  String? selectedMessageStudentId;
  String msgSearchQuery = '';

  /// One-shot, fire-and-forget user messages for async events (timer end,
  /// realtime chat notifications, cloud sync results), mirroring the web
  /// app's `msg()` toast. Screens listen via [toasts] and show a SnackBar.
  final StreamController<String> _toastController = StreamController<String>.broadcast();
  Stream<String> get toasts => _toastController.stream;
  void toast(String message) => _toastController.add(message);

  Future<void> init() async {
    _data = await _storage.loadData();

    final theme = await _storage.getTheme();
    themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;

    final soundKey = await _storage.getSound();
    sndType = TimerSoundX.fromKey(soundKey ?? 'beep');

    timerLeft = timerTotal;
    if (attDate.isEmpty) attDate = todayStr();

    await notificationService.init();

    await _initCloud();
    _ready = true;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.setTheme(themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  /// Persists [data] locally and triggers debounced cloud/board syncs,
  /// mirroring the web app's `save()`.
  Future<void> save() async {
    _data.modified = DateTime.now().millisecondsSinceEpoch;
    await _storage.saveData(_data);
    notifyListeners();
    scheduleCloudSave();
    scheduleBoardUpdate();
  }

  void notify() => notifyListeners();

  @override
  void dispose() {
    _timerHandle?.cancel();
    _boardUpdateTimer?.cancel();
    _cloudSaveTimer?.cancel();
    _boardPollTimer?.cancel();
    _boardViewerSpinTimer?.cancel();
    if (_teacherMsgChannel != null) {
      cloud.removeChannel(_teacherMsgChannel!);
    }
    soundService.dispose();
    _toastController.close();
    super.dispose();
  }
}
