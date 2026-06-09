import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

final authProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((e) => e.session?.user);
});

class AppDataNotifier extends StateNotifier<AppData> {
  AppDataNotifier() : super(AppData());

  Timer? _syncTimer;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final d = await SupabaseService.loadAppData();
    state = d;
    _loaded = true;
  }

  void _scheduleSave() {
    _syncTimer?.cancel();
    _syncTimer =
        Timer(const Duration(milliseconds: 900), () => SupabaseService.saveAppData(state));
  }

  void _update(AppData Function(AppData d) fn) {
    state = fn(state.deepCopy());
    _scheduleSave();
  }

  // Sınıf işlemleri
  void addClass(String name) {
    if (state.classes.contains(name.trim())) return;
    _update((d) {
      d.classes.add(name.trim());
      d.classCodes[name.trim()] = genClassCode();
      return d;
    });
  }

  void deleteClass(String name) {
    _update((d) {
      d.classes.remove(name);
      d.students.removeWhere((s) => s.className == name);
      d.classCodes.remove(name);
      return d;
    });
  }

  // Öğrenci işlemleri
  void addStudent(Student s) {
    _update((d) {
      d.students.add(s);
      return d;
    });
  }

  void updateStudent(Student s) {
    _update((d) {
      final idx = d.students.indexWhere((x) => x.id == s.id);
      if (idx >= 0) d.students[idx] = s;
      return d;
    });
  }

  void deleteStudent(String id) {
    _update((d) {
      d.students.removeWhere((s) => s.id == id);
      return d;
    });
  }

  void transferStudent(String id, String newClass) {
    _update((d) {
      final idx = d.students.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        d.students[idx] = d.students[idx].copyWith(className: newClass);
      }
      return d;
    });
  }

  // Puan işlemleri
  void changeScore(String studentId, int delta, String note) {
    _update((d) {
      final idx = d.students.indexWhere((s) => s.id == studentId);
      if (idx >= 0) {
        d.students[idx].history.add(ScoreHistoryEntry(
          delta: delta,
          note: note,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      return d;
    });
  }

  // Yoklama
  void setAttendance(
      String className, DateTime date, String studentId, String val) {
    _update((d) {
      final key =
          '${className}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      d.attendance[key] ??= {};
      d.attendance[key]![studentId] = val;
      return d;
    });
  }

  // Özel butonlar
  void saveCustomButtons(List<CustomButton> btns) {
    _update((d) {
      d.customBtns
        ..clear()
        ..addAll(btns);
      return d;
    });
  }

  // Sınıf kodu
  String regenClassCode(String className) {
    final code = genClassCode();
    _update((d) {
      d.classCodes[className] = code;
      return d;
    });
    return code;
  }

  // Zorla buluta kaydet
  Future<void> saveNow() => SupabaseService.saveAppData(state);

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final appDataProvider =
    StateNotifierProvider<AppDataNotifier, AppData>((ref) => AppDataNotifier());
