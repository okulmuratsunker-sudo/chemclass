import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_session.dart';
import '../models/student.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

/// Result of a sign-in/sign-up attempt.
class AuthResult {
  final bool ok;
  final bool needsConfirmation;
  final String? error;

  const AuthResult.success()
      : ok = true,
        needsConfirmation = false,
        error = null;
  const AuthResult.confirmation()
      : ok = true,
        needsConfirmation = true,
        error = null;
  const AuthResult.failure(this.error)
      : ok = false,
        needsConfirmation = false;
}

/// Central application state, mirroring `ders-takip.html`'s global
/// `students`/`sessions`/`filters`/`currentPage` plus its offline cache and
/// write queue.
class AppState extends ChangeNotifier {
  final SupabaseService _sb = SupabaseService();
  final StorageService _storage = StorageService();

  ThemeMode themeMode = ThemeMode.dark;

  bool _ready = false;
  bool get ready => _ready;

  User? user;
  bool get isAuthed => user != null;

  List<Student> students = [];
  List<LessonSession> sessions = [];

  DtPage currentPage = DtPage.dashboard;

  // ── Filters (Dersler sayfası) ─────────────────────────────────────────
  String filterStudentId = '';
  String filterPaid = ''; // '' | 'true' | 'false'
  String filterMonth = '';

  bool loading = false;
  bool offline = false;
  int queueLength = 0;

  final StreamController<String> _toastController = StreamController<String>.broadcast();
  Stream<String> get toasts => _toastController.stream;
  void toast(String message) => _toastController.add(message);

  Future<void> init() async {
    final theme = await _storage.getTheme();
    themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;

    user = await _sb.getSession();
    if (user != null) {
      await loadAll();
    }

    _ready = true;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.setTheme(themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setPage(DtPage page) {
    currentPage = page;
    notifyListeners();
  }

  void notify() => notifyListeners();

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<AuthResult> signIn(String email, String password) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) return const AuthResult.failure('E-posta ve şifre gerekli');
    try {
      final res = await _sb.signIn(e, password);
      user = res.user;
      notifyListeners();
      await loadAll();
      return const AuthResult.success();
    } catch (err) {
      final msg = err.toString();
      return AuthResult.failure(msg.contains('Invalid login credentials') ? 'E-posta veya şifre hatalı' : msg);
    }
  }

  Future<AuthResult> signUp(String email, String password) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) return const AuthResult.failure('E-posta ve şifre gerekli');
    try {
      final res = await _sb.signUp(e, password);
      if (res.user != null && res.session == null) {
        return const AuthResult.confirmation();
      }
      user = res.user;
      notifyListeners();
      await loadAll();
      return const AuthResult.success();
    } catch (err) {
      return AuthResult.failure(err.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _sb.signOut();
    } catch (_) {}
    user = null;
    students = [];
    sessions = [];
    currentPage = DtPage.dashboard;
    resetFilters();
    notifyListeners();
  }

  // ── Data loading ───────────────────────────────────────────────────────

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      await flushQueue();
      final fetchedStudents = await _sb.fetchStudents();
      final fetchedSessions = await _sb.fetchSessions();
      students = fetchedStudents;
      sessions = fetchedSessions;
      offline = false;
      await _storage.saveCache(students, sessions);
    } catch (_) {
      final (cachedStudents, cachedSessions) = await _storage.loadCache();
      students = cachedStudents;
      sessions = cachedSessions;
      offline = true;
    }
    queueLength = (await _storage.getQueue()).length;
    loading = false;
    notifyListeners();
  }

  // ── Offline write queue ───────────────────────────────────────────────

  Future<void> flushQueue() async {
    final queue = await _storage.getQueue();
    if (queue.isEmpty) return;
    final idMap = <String, String>{};
    for (final op in queue) {
      try {
        final t = op['t'] as String?;
        final table = op['table'] as String?;
        if (t == 'insert') {
          final data = Map<String, dynamic>.from(op['data'] as Map);
          if (table == 'students') {
            final row = await _sb.insertStudent(data);
            final tmpId = op['tmpId'] as String?;
            if (tmpId != null) idMap[tmpId] = row.id;
          } else if (table == 'sessions') {
            final row = await _sb.insertSession(data);
            final tmpId = op['tmpId'] as String?;
            if (tmpId != null) idMap[tmpId] = row.id;
          }
        } else if (t == 'update') {
          final id = idMap[op['id']] ?? op['id'] as String;
          final data = Map<String, dynamic>.from(op['data'] as Map);
          if (!id.startsWith('tmp_')) {
            if (table == 'students') {
              await _sb.updateStudent(id, data);
            } else if (table == 'sessions') {
              await _sb.updateSession(id, data);
            }
          }
        } else if (t == 'delete') {
          final id = idMap[op['id']] ?? op['id'] as String;
          if (!id.startsWith('tmp_')) {
            if (table == 'students') {
              await _sb.deleteStudent(id);
            } else if (table == 'sessions') {
              await _sb.deleteSession(id);
            }
          }
        } else if (t == 'cascade_delete') {
          final id = idMap[op['id']] ?? op['id'] as String;
          if (!id.startsWith('tmp_')) {
            await _sb.deleteSessionsByStudent(id);
            await _sb.deleteStudent(id);
          }
        }
      } catch (_) {
        // Best-effort: skip and continue with remaining ops.
      }
    }
    await _storage.clearQueue();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String studentName(String id) {
    for (final s in students) {
      if (s.id == id) return s.name;
    }
    return '?';
  }

  List<LessonSession> sessionsFor(String studentId) =>
      sessions.where((s) => s.studentId == studentId).toList();

  double unpaidFor(String studentId) =>
      sessionsFor(studentId).where((s) => !s.paid).fold(0.0, (a, s) => a + s.amount);

  /// Fetches all sessions for [studentId], mirroring `openStudentDetail()`'s
  /// and `openReceipt()`'s direct Supabase queries. Falls back to the cached
  /// [sessionsFor] list when offline.
  Future<List<LessonSession>> fetchSessionsForStudent(String studentId, {bool ascending = false}) async {
    if (!offline) {
      try {
        return await _sb.fetchSessionsByStudent(studentId, ascending: ascending);
      } catch (_) {
        offline = true;
      }
    }
    final list = sessionsFor(studentId);
    list.sort((a, b) => ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    return list;
  }

  // ── Dashboard aggregates ──────────────────────────────────────────────

  double get totalIncome => sessions.fold(0.0, (a, s) => a + s.amount);
  List<LessonSession> get unpaidSessions => sessions.where((s) => !s.paid).toList();
  double get unpaidTotal => unpaidSessions.fold(0.0, (a, s) => a + s.amount);
  double get totalDuration => sessions.fold(0.0, (a, s) => a + s.duration);
  List<LessonSession> get recentSessions => sessions.take(5).toList();

  // ── Sessions filters ───────────────────────────────────────────────────

  List<LessonSession> get filteredSessions {
    return sessions.where((s) {
      if (filterStudentId.isNotEmpty && s.studentId != filterStudentId) return false;
      if (filterPaid.isNotEmpty && s.paid != (filterPaid == 'true')) return false;
      if (filterMonth.isNotEmpty && (s.date.length < 7 || s.date.substring(0, 7) != filterMonth)) return false;
      return true;
    }).toList();
  }

  void setFilter({String? studentId, String? paid, String? month}) {
    if (studentId != null) filterStudentId = studentId;
    if (paid != null) filterPaid = paid;
    if (month != null) filterMonth = month;
    notifyListeners();
  }

  void resetFilters() {
    filterStudentId = '';
    filterPaid = '';
    filterMonth = '';
    notifyListeners();
  }

  // ── Reports ────────────────────────────────────────────────────────────

  /// Income per month for the last 6 months (oldest first), keyed by `"YYYY-MM"`.
  Map<String, double> monthlyIncome() {
    final now = DateTime.now();
    final months = <String>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add('${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}');
    }
    final byMonth = {for (final m in months) m: 0.0};
    for (final s in sessions) {
      if (s.date.length < 7) continue;
      final m = s.date.substring(0, 7);
      if (byMonth.containsKey(m)) byMonth[m] = byMonth[m]! + s.amount;
    }
    return byMonth;
  }

  // ── Student CRUD ───────────────────────────────────────────────────────

  Future<void> saveStudent({String? id, required String name, required double hourlyRate}) async {
    final data = {'name': name, 'hourly_rate': hourlyRate};
    if (!offline) {
      try {
        if (id != null) {
          await _sb.updateStudent(id, data);
        } else {
          await _sb.insertStudent(data);
        }
        toast(id != null ? 'Güncellendi' : 'Öğrenci eklendi');
        await loadAll(silent: true);
        return;
      } catch (_) {
        offline = true;
      }
    }
    if (id != null) {
      final idx = students.indexWhere((s) => s.id == id);
      if (idx != -1) students[idx] = students[idx].copyWith(name: name, hourlyRate: hourlyRate);
      await _storage.addQueueOp({'t': 'update', 'table': 'students', 'id': id, 'data': data});
    } else {
      final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      students.add(Student(id: tmpId, name: name, hourlyRate: hourlyRate));
      await _storage.addQueueOp({'t': 'insert', 'table': 'students', 'tmpId': tmpId, 'data': data});
    }
    students.sort((a, b) => a.name.compareTo(b.name));
    await _storage.saveCache(students, sessions);
    queueLength = (await _storage.getQueue()).length;
    toast(id != null ? 'Güncellendi (çevrimdışı)' : 'Öğrenci eklendi (çevrimdışı)');
    notifyListeners();
  }

  Future<void> deleteStudent(String id) async {
    if (!offline) {
      try {
        await _sb.deleteSessionsByStudent(id);
        await _sb.deleteStudent(id);
        toast('Öğrenci silindi');
        await loadAll(silent: true);
        return;
      } catch (_) {
        offline = true;
      }
    }
    students.removeWhere((s) => s.id == id);
    sessions.removeWhere((s) => s.studentId == id);
    if (!id.startsWith('tmp_')) {
      await _storage.addQueueOp({'t': 'cascade_delete', 'id': id});
    }
    await _storage.saveCache(students, sessions);
    queueLength = (await _storage.getQueue()).length;
    toast('Öğrenci silindi (çevrimdışı)');
    notifyListeners();
  }

  // ── Session CRUD ───────────────────────────────────────────────────────

  Future<void> saveSession({
    String? id,
    required String studentId,
    required String date,
    required double duration,
    required double amount,
    required bool paid,
    String? notes,
  }) async {
    final data = {
      'student_id': studentId,
      'date': date,
      'duration': duration,
      'amount': amount,
      'paid': paid,
      'notes': notes,
    };
    if (!offline) {
      try {
        if (id != null) {
          await _sb.updateSession(id, data);
        } else {
          await _sb.insertSession(data);
        }
        toast(id != null ? 'Ders güncellendi' : 'Ders eklendi');
        await loadAll(silent: true);
        return;
      } catch (_) {
        offline = true;
      }
    }
    if (id != null) {
      final idx = sessions.indexWhere((s) => s.id == id);
      if (idx != -1) {
        sessions[idx] = sessions[idx].copyWith(
          studentId: studentId,
          date: date,
          duration: duration,
          amount: amount,
          paid: paid,
          notes: notes,
        );
      }
      await _storage.addQueueOp({'t': 'update', 'table': 'sessions', 'id': id, 'data': data});
    } else {
      final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      sessions.insert(
        0,
        LessonSession(
          id: tmpId,
          studentId: studentId,
          date: date,
          duration: duration,
          amount: amount,
          paid: paid,
          notes: notes,
        ),
      );
      await _storage.addQueueOp({'t': 'insert', 'table': 'sessions', 'tmpId': tmpId, 'data': data});
    }
    await _storage.saveCache(students, sessions);
    queueLength = (await _storage.getQueue()).length;
    toast(id != null ? 'Ders güncellendi (çevrimdışı)' : 'Ders eklendi (çevrimdışı)');
    notifyListeners();
  }

  Future<void> togglePaid(String id, bool current) async {
    if (!offline) {
      try {
        await _sb.updateSession(id, {'paid': !current});
        toast(!current ? 'Ödendi işaretlendi' : 'Ödenmedi olarak değiştirildi');
        await loadAll(silent: true);
        return;
      } catch (_) {
        offline = true;
      }
    }
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx != -1) sessions[idx] = sessions[idx].copyWith(paid: !current);
    if (!id.startsWith('tmp_')) {
      await _storage.addQueueOp({'t': 'update', 'table': 'sessions', 'id': id, 'data': {'paid': !current}});
    }
    await _storage.saveCache(students, sessions);
    queueLength = (await _storage.getQueue()).length;
    toast(!current ? 'Ödendi işaretlendi (çevrimdışı)' : 'Ödenmedi olarak değiştirildi (çevrimdışı)');
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    if (!offline) {
      try {
        await _sb.deleteSession(id);
        toast('Ders silindi');
        await loadAll(silent: true);
        return;
      } catch (_) {
        offline = true;
      }
    }
    sessions.removeWhere((s) => s.id == id);
    if (!id.startsWith('tmp_')) {
      await _storage.addQueueOp({'t': 'delete', 'table': 'sessions', 'id': id});
    }
    await _storage.saveCache(students, sessions);
    queueLength = (await _storage.getQueue()).length;
    toast('Ders silindi (çevrimdışı)');
    notifyListeners();
  }

  @override
  void dispose() {
    _toastController.close();
    super.dispose();
  }
}
