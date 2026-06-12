import 'helpers.dart';

/// Realtime broadcast channel naming shared with the teacher app - when the
/// teacher sends a message or assignment, it broadcasts a ping on these
/// channels, and a subscribed student app refetches immediately instead of
/// waiting for its next poll. Best-effort "live" layer on top of polling.

String slugifyClassName(String className) {
  final lower = trLower(className.trim())
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');
  final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return slug.replaceAll(RegExp(r'^-+|-+$'), '');
}

String classChannel(String className) => 'chemclass-class-${slugifyClassName(className)}';

String studentChannel(String studentId) => 'chemclass-student-$studentId';

const String everyoneChannel = 'chemclass-everyone';

const String evtNewMessage = 'new_message';
const String evtNewAssignment = 'new_assignment';
