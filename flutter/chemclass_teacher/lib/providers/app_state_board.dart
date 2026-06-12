part of 'app_state.dart';

/// Tahta Modu (board) - host side mirrors `makeBoardSnapshot()` /
/// `createBoardCode()` / `refreshBoardSession()` / `manualRefreshBoard()` /
/// `closeBoardSession()` / `scheduleBoardUpdate()` / `setBoardView()`; viewer
/// side mirrors `tahta.html`'s `connectBoard()` / `poll()` / `processData()`
/// / `triggerSpin()`.
extension AppStateBoard on AppState {
  // ── Host ───────────────────────────────────────────────────────────────

  Map<String, dynamic> makeBoardSnapshot(String cls) {
    final students = getByClass(cls.isEmpty ? null : cls).map((s) => s.toBoardJson()).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final last8 = picked.length > 8 ? picked.sublist(picked.length - 8) : List<String>.from(picked);
    final recentNames = last8
        .map((id) => data.students.firstWhereOrNull((s) => s.id == id))
        .where((s) => s != null && (cls.isEmpty || s.className == cls))
        .map((s) => s!.name)
        .toList()
        .reversed
        .toList();

    final lastPickStudent = lastPick != null ? data.students.firstWhereOrNull((s) => s.id == lastPick) : null;
    final timerEnd =
        timerRunning ? DateTime.now().add(Duration(seconds: timerLeft)).toIso8601String() : null;

    return {
      'className': cls.isNotEmpty ? cls : 'Tüm Öğrenciler',
      'students': students,
      'recent': recentNames,
      'view': boardCurrentView,
      'lastPick': lastPickStudent != null
          ? {
              'id': lastPickStudent.id,
              'name': lastPickStudent.name,
              'no': lastPickStudent.no,
              'score': lastPickStudent.score,
              'color': lastPickStudent.color,
            }
          : null,
      'pickTime': lastPickTime?.toIso8601String(),
      'groups': groups.map((g) => g.toBoardJson()).toList(),
      'timerEnd': timerEnd,
      'timerPaused': !timerRunning,
      'timerRemaining': timerLeft,
      'timerTotal': timerTotal,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Creates a fresh 6-digit board code for [cls]. Returns an error message,
  /// or `null` on success.
  Future<String?> createBoardCode(String cls) async {
    sbUser ??= await cloud.getSession();
    if (sbUser == null) return 'Tahta kodu için önce buluta giriş yapın';
    if (cls.isEmpty) return 'Tahta için sınıf seçin';

    activeBoardCode = randomBoardCode();
    activeBoardClass = cls;
    final row = {
      'code': activeBoardCode,
      'user_id': sbUser!.id,
      'class_name': cls,
      'app_data': makeBoardSnapshot(cls),
      'active': true,
      'expires_at': DateTime.now().add(Duration(hours: shareHours)).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await cloud.upsertBoardSession(row);
    } catch (e) {
      activeBoardCode = '';
      activeBoardClass = '';
      return 'Tahta kodu oluşturulamadı: $e';
    }
    notify();
    toast('Tahta kodu oluşturuldu ✓');
    return null;
  }

  Future<void> refreshBoardSession() async {
    if (activeBoardCode.isEmpty) return;
    sbUser ??= await cloud.getSession();
    if (sbUser == null) return;
    try {
      await cloud.updateBoardSession(activeBoardCode, sbUser!.id, {
        'class_name': activeBoardClass,
        'app_data': makeBoardSnapshot(activeBoardClass),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Returns an error message, or `null` on success.
  Future<String?> manualRefreshBoard() async {
    if (activeBoardCode.isEmpty) return 'Önce tahta kodu oluşturun';
    await refreshBoardSession();
    toast('Tahta güncellendi ✓');
    return null;
  }

  void scheduleBoardUpdate() {
    if (activeBoardCode.isEmpty || sbUser == null) return;
    _boardUpdateTimer?.cancel();
    _boardUpdateTimer = Timer(const Duration(milliseconds: 1200), refreshBoardSession);
  }

  void setBoardView(String v) {
    boardCurrentView = v;
    scheduleBoardUpdate();
  }

  /// Returns an error message, or `null` on success.
  Future<String?> closeBoardSession() async {
    if (activeBoardCode.isEmpty) return 'Açık tahta kodu yok';
    sbUser ??= await cloud.getSession();
    if (sbUser != null) {
      try {
        await cloud.updateBoardSession(activeBoardCode, sbUser!.id, {
          'active': false,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
    activeBoardCode = '';
    activeBoardClass = '';
    _boardUpdateTimer?.cancel();
    notify();
    toast('Tahta bağlantısı kapatıldı');
    return null;
  }

  // ── Viewer ─────────────────────────────────────────────────────────────

  /// Connects to a board session by its 6-digit [code] and starts polling.
  Future<void> connectBoard(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      boardViewerError = '6 haneli sayı girin';
      notify();
      return;
    }
    try {
      final row = await cloud.fetchBoardSession(code);
      if (row == null) {
        boardViewerError = 'Kod bulunamadı veya geçersiz';
        notify();
        return;
      }
      final expiresAt = row['expires_at'] as String?;
      if (expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        boardViewerError = 'Bu kodun süresi doldu';
        notify();
        return;
      }
      boardViewerCode = code;
      boardViewerConnected = true;
      boardViewerError = '';
      boardViewerMode = 'auto';
      boardViewerManualView = 'list';
      boardViewerPickResult = null;
      _boardViewerLastPickTime = null;
      _processBoardData(row);
      _startBoardPolling();
      notify();
    } catch (_) {
      boardViewerError = 'Kod bulunamadı veya geçersiz';
      notify();
    }
  }

  void disconnectBoard() {
    _boardPollTimer?.cancel();
    _boardPollTimer = null;
    _boardViewerSpinTimer?.cancel();
    _boardViewerSpinTimer = null;
    boardViewerConnected = false;
    boardViewerCode = '';
    boardViewerData = null;
    boardViewerError = '';
    boardViewerPickResult = null;
    boardViewerSpinning = false;
    boardViewerSpinName = '';
    _boardViewerLastPickTime = null;
    notify();
  }

  /// Manually switches the local view (stops following the teacher's view).
  void setBoardViewerView(String v) {
    boardViewerMode = 'manual';
    boardViewerManualView = v;
    notify();
  }

  void _startBoardPolling() {
    _boardPollTimer?.cancel();
    _boardPollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollBoard());
  }

  Future<void> _pollBoard() async {
    if (!boardViewerConnected || boardViewerCode.isEmpty) return;
    try {
      final row = await cloud.fetchBoardSession(boardViewerCode);
      if (row == null) {
        boardViewerError = '⚠️ Bağlantı yok';
        notify();
        return;
      }
      final expiresAt = row['expires_at'] as String?;
      if (expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        disconnectBoard();
        toast('Tahta oturumu sona erdi.');
        return;
      }
      boardViewerError = '';
      _processBoardData(row);
      notify();
    } catch (_) {
      boardViewerError = '⚠️ Bağlantı yok';
      notify();
    }
  }

  void _processBoardData(Map<String, dynamic> row) {
    final d = Map<String, dynamic>.from(row['app_data'] as Map? ?? {});
    boardViewerData = d;
    boardViewerUpdatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now();

    final targetView = (d['view'] as String?) ?? 'list';
    if (boardViewerMode == 'auto') {
      boardViewerManualView = targetView;
    }

    final newPickTime = d['pickTime'] as String?;
    final lastPick = d['lastPick'] as Map<String, dynamic>?;
    final students = (d['students'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (newPickTime != null && newPickTime != _boardViewerLastPickTime && lastPick != null) {
      _boardViewerLastPickTime = newPickTime;
      if (boardViewerMode == 'auto') {
        boardViewerManualView = 'pick';
        _triggerBoardSpin(lastPick, students);
      } else if (boardViewerManualView == 'pick') {
        _triggerBoardSpin(lastPick, students);
      } else {
        boardViewerPickResult = lastPick;
      }
    } else if (!boardViewerSpinning) {
      boardViewerPickResult = lastPick;
    }
  }

  void _triggerBoardSpin(Map<String, dynamic> pick, List<Map<String, dynamic>> students) {
    if (boardViewerSpinning) return;
    boardViewerSpinning = true;
    boardViewerPickResult = null;

    var pool = students
        .map((s) => s['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty && n != pick['name'])
        .toList();
    if (pool.isEmpty) pool = ['...'];

    var spins = 0;
    const total = 20;
    _boardViewerSpinTimer?.cancel();
    _boardViewerSpinTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      boardViewerSpinName = pool[spins % pool.length];
      spins++;
      notify();
      if (spins >= total) {
        timer.cancel();
        boardViewerSpinning = false;
        boardViewerPickResult = pick;
        notify();
      }
    });
  }

  /// Live remaining seconds for the synced timer view.
  int get boardViewerTimerRemaining {
    final d = boardViewerData;
    if (d == null) return 0;
    final timerEnd = d['timerEnd'] as String?;
    final timerPaused = d['timerPaused'] as bool? ?? true;
    if (!timerPaused && timerEnd != null) {
      final end = DateTime.tryParse(timerEnd);
      if (end != null) {
        final remaining = end.difference(DateTime.now()).inMilliseconds / 1000;
        return remaining > 0 ? remaining.ceil() : 0;
      }
    }
    return (d['timerRemaining'] as num?)?.toInt() ?? 0;
  }

  bool get boardViewerTimerRunning {
    final d = boardViewerData;
    if (d == null) return false;
    return !(d['timerPaused'] as bool? ?? true);
  }
}
