part of 'app_state.dart';

/// A processed row for the teacher-side message history list, mirroring
/// `renderMsgHistory()`'s `{...m, _who, _out}` shape.
class MsgHistoryRow {
  final ChatMessage message;
  final String who;
  final bool out;

  MsgHistoryRow({required this.message, required this.who, required this.out});
}

/// Mesajlar (teacher <-> student chat) - mirrors `loadTeacherMessages()` /
/// `sendTeacherMessage()` / `renderMsgHistory()` / `openConversation()` /
/// `sendConversationReply()` / `setupTeacherRealtime()`.
extension AppStateMessages on AppState {
  Future<void> loadTeacherMessages() async {
    if (sbUser == null) return;
    try {
      final rows = await cloud.fetchTeacherMessages(sbUser!.id);
      teacherMessages = rows.map(ChatMessage.fromJson).toList();
      notify();
    } catch (_) {}
  }

  /// Students available for the "tek öğrenci" message scope, filtered by
  /// [selectedMessageClass] and sorted by name.
  List<Student> get messageStudentOptions {
    final list = data.students
        .where((s) => selectedMessageClass.isEmpty || s.className == selectedMessageClass)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void setMsgSearchQuery(String q) {
    msgSearchQuery = q;
    notify();
  }

  /// Mirrors `renderMsgHistory()`: enriches each message with who it's
  /// to/from and filters by [msgSearchQuery].
  List<MsgHistoryRow> get filteredMessageHistory {
    final q = trLower(msgSearchQuery.trim());
    final rows = teacherMessages.map((m) {
      final out = m.sender == 'teacher';
      String who;
      if (out) {
        if (m.studentId != null) {
          final s = data.students.firstWhereOrNull((x) => x.id == m.studentId);
          who = s?.name ?? 'Öğrenci';
        } else {
          who = '📢 ${m.className ?? 'Herkes'}';
        }
      } else {
        final s = data.students.firstWhereOrNull((x) => x.id == m.studentId);
        who = m.senderName.isNotEmpty ? m.senderName : (s?.name ?? 'Öğrenci');
      }
      return MsgHistoryRow(message: m, who: who, out: out);
    }).toList();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => trLower(r.who).contains(q) || trLower(r.message.body).contains(q))
        .toList();
  }

  /// Sends a message to the selected scope (single student / whole class /
  /// everyone). Returns an error message, or `null` on success.
  Future<String?> sendTeacherMessage(String body) async {
    if (sbUser == null) return 'Önce bulut hesabına giriş yapmalısınız';
    final b = body.trim();
    if (b.isEmpty) return 'Mesaj yazın';

    String? studentId;
    String? className;
    String label;
    switch (selectedMessageScope) {
      case 'student':
        final s = data.students.firstWhereOrNull((x) => x.id == selectedMessageStudentId);
        if (s == null) return 'Öğrenci seçin';
        studentId = s.id;
        className = s.className;
        label = s.name;
        break;
      case 'class':
        if (selectedMessageClass.isEmpty) return 'Sınıf seçin';
        className = selectedMessageClass;
        label = '$className sınıfının tamamı (toplu)';
        break;
      default:
        label = 'Tüm öğrencileriniz (toplu)';
    }

    final message = ChatMessage(
      id: '',
      teacherId: sbUser!.id,
      studentId: studentId,
      className: className,
      sender: 'teacher',
      senderName: 'Öğretmen',
      body: b,
      createdAt: DateTime.now(),
    );
    try {
      await cloud.insertMessage(message.toInsertJson());
    } catch (e) {
      return 'Gönderilemedi: $e';
    }
    toast('Gönderildi → $label');
    await loadTeacherMessages();
    return null;
  }

  /// Opens the 1:1 conversation with [studentId]. Returns an error message,
  /// or `null` on success.
  String? openConversation(String studentId) {
    final s = data.students.firstWhereOrNull((x) => x.id == studentId);
    if (s == null) return 'Öğrenci bulunamadı (silinmiş olabilir)';
    convStudentId = studentId;
    notify();
    return null;
  }

  void closeConversation() {
    convStudentId = null;
    notify();
  }

  String get conversationTitle {
    final s = data.students.firstWhereOrNull((x) => x.id == convStudentId);
    return s != null ? '💬 ${s.name} (${s.className})' : '';
  }

  /// Messages in the open 1:1 conversation, oldest first.
  List<ChatMessage> get conversationMessages {
    if (convStudentId == null) return [];
    final thread = teacherMessages.where((m) => m.studentId == convStudentId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return thread;
  }

  /// Returns an error message, or `null` on success.
  Future<String?> sendConversationReply(String body) async {
    if (sbUser == null) return 'Önce bulut hesabına giriş yapmalısınız';
    final s = data.students.firstWhereOrNull((x) => x.id == convStudentId);
    if (s == null) return 'Öğrenci bulunamadı';
    final b = body.trim();
    if (b.isEmpty) return 'Mesaj yazın';

    final message = ChatMessage(
      id: '',
      teacherId: sbUser!.id,
      studentId: s.id,
      className: s.className,
      sender: 'teacher',
      senderName: 'Öğretmen',
      body: b,
      createdAt: DateTime.now(),
    );
    try {
      await cloud.insertMessage(message.toInsertJson());
    } catch (e) {
      return 'Gönderilemedi: $e';
    }
    await loadTeacherMessages();
    return null;
  }

  /// Subscribes to incoming student messages and surfaces them as a toast +
  /// system notification, mirroring `setupTeacherRealtime()`.
  void setupTeacherRealtime() {
    if (sbUser == null) return;
    if (_teacherMsgChannel != null) {
      cloud.removeChannel(_teacherMsgChannel!);
      _teacherMsgChannel = null;
    }
    _teacherMsgChannel = cloud.subscribeTeacherMessages(sbUser!.id, (row) {
      if (row['sender']?.toString() != 'student') return;
      final senderName = row['sender_name']?.toString();
      final name = (senderName != null && senderName.isNotEmpty) ? senderName : 'Bir öğrenci';
      final body = row['body']?.toString() ?? '';
      unawaited(notificationService.show(name, body));
      toast('💬 $name: $body');
      loadTeacherMessages();
    });
  }
}
