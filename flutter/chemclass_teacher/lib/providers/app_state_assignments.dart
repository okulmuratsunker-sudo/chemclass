part of 'app_state.dart';

/// Maps a file extension to a best-effort content type for storage uploads
/// (the original web app reads this off the browser `File.type`).
String _guessContentType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'zip':
      return 'application/zip';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}

/// Ödevler / Duyurular / Görevler (assignments sent to students) - mirrors
/// `loadTeacherAssignments()` / `saveAssignment()` / `deleteAssignment()` /
/// `uploadClassFile()` / `cleanupOldFiles()`.
extension AppStateAssignments on AppState {
  Future<void> loadTeacherAssignments() async {
    if (sbUser == null) return;
    try {
      final rows = await cloud.fetchAssignments(sbUser!.id);
      teacherAssignments = rows.map(Assignment.fromJson).toList();
      notify();
    } catch (_) {}
  }

  List<Assignment> get filteredAssignments {
    if (selectedAssignmentFilterClass.isEmpty) return teacherAssignments;
    return teacherAssignments.where((a) => a.className == selectedAssignmentFilterClass).toList();
  }

  /// Sends a new assignment/announcement/task to [className]. Returns an
  /// error message, or `null` on success.
  Future<String?> saveAssignment({
    required String className,
    required String type,
    required String title,
    String body = '',
    String? dueDate,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    if (sbUser == null) return 'Önce bulut hesabına giriş yapmalısınız';
    if (className.isEmpty) return 'Sınıf seçin';
    final t = title.trim();
    if (t.isEmpty) return 'Başlık girin';

    Map<String, String>? fileInfo;
    if (fileBytes != null && fileName != null) {
      fileInfo = await uploadClassFile(fileName, fileBytes);
      if (fileInfo == null) return 'Dosya yüklenemedi';
    }

    final assignment = Assignment(
      id: '',
      teacherId: sbUser!.id,
      className: className,
      type: type,
      title: t,
      body: body.trim(),
      dueDate: dueDate,
      fileUrl: fileInfo?['url'],
      fileName: fileInfo?['name'],
      filePath: fileInfo?['path'],
      createdAt: DateTime.now(),
    );
    try {
      await cloud.insertAssignment(assignment.toInsertJson());
    } catch (e) {
      return 'Gönderilemedi: $e';
    }
    toast('Öğrencilere gönderildi ✓');
    await loadTeacherAssignments();
    return null;
  }

  Future<void> deleteAssignment(String id) async {
    if (sbUser == null) return;
    final a = teacherAssignments.firstWhereOrNull((x) => x.id == id);
    try {
      await cloud.deleteAssignment(id, sbUser!.id);
    } catch (e) {
      toast('Silinemedi: $e');
      return;
    }
    if (a?.filePath != null && a!.filePath!.isNotEmpty) {
      try {
        await cloud.removeFiles([a.filePath!]);
      } catch (_) {}
    }
    toast('Silindi');
    await loadTeacherAssignments();
  }

  /// Uploads [bytes] to the assignment files bucket, mirroring
  /// `uploadClassFile()`. Returns `{url, path, name}`, or `null` on failure.
  Future<Map<String, String>?> uploadClassFile(String fileName, Uint8List bytes) async {
    if (sbUser == null) return null;
    final dot = fileName.lastIndexOf('.');
    var ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : 'bin';
    ext = ext.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (ext.isEmpty) ext = 'bin';
    final path = '${sbUser!.id}/${uid()}.$ext';
    try {
      await cloud.uploadFile(path, bytes, _guessContentType(fileName));
    } catch (e) {
      toast('Dosya yüklenemedi: $e');
      return null;
    }
    await cleanupOldFiles();
    final url = cloud.getPublicUrl(path);
    return {'url': url, 'path': path, 'name': fileName};
  }

  /// Keeps only the 3 most-recently uploaded files per teacher, mirroring
  /// `cleanupOldFiles()`.
  Future<void> cleanupOldFiles() async {
    if (sbUser == null) return;
    try {
      final list = await cloud.listFiles(sbUser!.id);
      if (list.length <= 3) return;
      final old = list.skip(3).map((f) => '${sbUser!.id}/${f.name}').toList();
      if (old.isNotEmpty) await cloud.removeFiles(old);
    } catch (_) {}
  }
}
