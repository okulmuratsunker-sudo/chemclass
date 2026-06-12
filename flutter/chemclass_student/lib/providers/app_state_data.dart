part of 'app_state.dart';

/// Polling-based "live" data: score, class leaderboard, assignments and
/// messages — mirrors the Tahta board viewer's poll-for-updates pattern,
/// since the anon role has no Realtime access to these tables.
extension AppStateData on AppState {
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Subscribes to Realtime broadcast pings the teacher app sends when it
  /// posts a message/assignment for this student, this student's class, or
  /// everyone, so [refresh] runs immediately instead of on the next poll.
  void startRealtime() {
    stopRealtime();
    final s = session;
    if (s == null) return;
    for (final ch in [studentChannel(s.studentId), classChannel(s.className), everyoneChannel]) {
      _realtimeChannels.add(_api.subscribeBroadcast(ch, () => refresh()));
    }
  }

  void stopRealtime() {
    for (final ch in _realtimeChannels) {
      _api.removeChannel(ch);
    }
    _realtimeChannels.clear();
  }

  Future<void> refresh() async {
    final s = session;
    if (s == null) return;
    try {
      final data = await _api.getData(s.token);

      final studentJson = data['student'] as Map<String, dynamic>?;
      if (studentJson != null) {
        studentInfo = StudentInfo.fromJson(studentJson);
        s.score = studentInfo!.score;
        s.studentName = studentInfo!.name;
        await _storage.saveSession(s);
      }

      leaderboard = (data['leaderboard'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final newAssignments =
          (data['assignments'] as List? ?? []).map((e) => Assignment.fromJson(e as Map<String, dynamic>)).toList();
      final newMessages =
          (data['messages'] as List? ?? []).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();

      if (!_seenInitialized) {
        await _storage.setSeenIds(prefsSeenAssignmentsKey, newAssignments.map((a) => a.id).toSet());
        await _storage.setSeenIds(prefsSeenMessagesKey, newMessages.map((m) => m.id).toSet());
        _seenInitialized = true;
      } else {
        await _notifyNewItems(newAssignments, newMessages);
      }

      assignments = newAssignments;
      messages = newMessages;
      notify();
    } catch (_) {
      // Sessizce yoksay: bağlantı sorunlarında önceki veriler görünür kalır.
    }
  }

  Future<void> _notifyNewItems(List<Assignment> newAssignments, List<ChatMessage> newMessages) async {
    final seenAssignments = await _storage.getSeenIds(prefsSeenAssignmentsKey);
    final seenMessages = await _storage.getSeenIds(prefsSeenMessagesKey);

    for (final a in newAssignments) {
      if (!seenAssignments.contains(a.id)) {
        final title = '${asgTypeLabel[a.type] ?? a.type} • ${a.className}';
        unawaited(notificationService.show(title, a.title));
        toast('$title: ${a.title}');
      }
    }
    for (final m in newMessages) {
      if (m.sender == 'teacher' && !seenMessages.contains(m.id)) {
        unawaited(notificationService.show('💬 Öğretmen', m.body));
        toast('💬 Öğretmen: ${m.body}');
      }
    }

    await _storage.setSeenIds(prefsSeenAssignmentsKey, newAssignments.map((a) => a.id).toSet());
    await _storage.setSeenIds(prefsSeenMessagesKey, newMessages.map((m) => m.id).toSet());
  }

  /// This student's 1-based position in the class leaderboard, or `null`.
  int? get myRank {
    final s = session;
    if (s == null) return null;
    final idx = leaderboard.indexWhere((e) => e.id == s.studentId);
    return idx >= 0 ? idx + 1 : null;
  }
}
