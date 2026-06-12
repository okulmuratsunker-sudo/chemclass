import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Wraps a (re-configurable) [SupabaseClient] for the main ChemClass cloud
/// backend: auth, `chemclass_data` sync, board sessions, assignments,
/// messages and file storage.
///
/// Unlike the global `Supabase.instance` singleton, this client can be
/// re-created at runtime with a different URL/anon key, mirroring the web
/// app's configurable "Bulut" settings.
class SupabaseService {
  SupabaseClient _client;
  String url;
  String anonKey;

  SupabaseService({String? url, String? anonKey})
      : url = url ?? defaultSupabaseUrl,
        anonKey = anonKey ?? defaultSupabaseAnonKey,
        _client = SupabaseClient(url ?? defaultSupabaseUrl, anonKey ?? defaultSupabaseAnonKey);

  SupabaseClient get client => _client;

  Future<void> reinit(String newUrl, String newKey) async {
    if (newUrl == url && newKey == anonKey) return;
    url = newUrl;
    anonKey = newKey;
    _client = SupabaseClient(newUrl, newKey);
  }

  User? get currentUser => _client.auth.currentUser;

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<User?> getSession() async {
    final session = _client.auth.currentSession;
    return session?.user;
  }

  // ── chemclass_data (full app backup / sync) ────────────────────────────

  Future<Map<String, dynamic>?> fetchAppData(String userId) async {
    return await _client
        .from('chemclass_data')
        .select('app_data,updated_at')
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> upsertAppData(String userId, Map<String, dynamic> appData) async {
    await _client.from('chemclass_data').upsert({
      'user_id': userId,
      'app_data': appData,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // ── Board sessions (Tahta Modu) ─────────────────────────────────────────

  Future<void> upsertBoardSession(Map<String, dynamic> row) async {
    await _client.from('chemclass_board_sessions').upsert(row, onConflict: 'code');
  }

  Future<void> updateBoardSession(
      String code, String userId, Map<String, dynamic> fields) async {
    await _client
        .from('chemclass_board_sessions')
        .update(fields)
        .eq('code', code)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>?> fetchBoardSession(String code) async {
    return await _client
        .from('chemclass_board_sessions')
        .select('code,class_name,app_data,updated_at,active,expires_at')
        .eq('code', code)
        .eq('active', true)
        .maybeSingle();
  }

  // ── Assignments ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAssignments(String teacherId) async {
    final rows = await _client
        .from('chemclass_assignments')
        .select('*')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(150);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertAssignment(Map<String, dynamic> row) async {
    await _client.from('chemclass_assignments').insert(row);
  }

  Future<void> deleteAssignment(String id, String teacherId) async {
    await _client
        .from('chemclass_assignments')
        .delete()
        .eq('id', id)
        .eq('teacher_id', teacherId);
  }

  // ── Storage (assignment file attachments) ───────────────────────────────

  Future<void> uploadFile(String path, Uint8List bytes, String contentType) async {
    await _client.storage.from(filesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
  }

  String getPublicUrl(String path) {
    return _client.storage.from(filesBucket).getPublicUrl(path);
  }

  Future<List<FileObject>> listFiles(String prefix) async {
    return await _client.storage.from(filesBucket).list(
          path: prefix,
          searchOptions: const SearchOptions(sortBy: SortBy(column: 'created_at', order: 'desc')),
        );
  }

  Future<void> removeFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(filesBucket).remove(paths);
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchTeacherMessages(String teacherId) async {
    final rows = await _client
        .from('chemclass_messages')
        .select('*')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(300);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertMessage(Map<String, dynamic> row) async {
    await _client.from('chemclass_messages').insert(row);
  }

  RealtimeChannel subscribeTeacherMessages(
    String teacherId,
    void Function(Map<String, dynamic> row) onInsert,
  ) {
    final channel = _client.channel('chemclass-teacher-$teacherId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chemclass_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'teacher_id',
        value: teacherId,
      ),
      callback: (payload) => onInsert(payload.newRecord),
    );
    channel.subscribe();
    return channel;
  }

  void removeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }

  /// Best-effort "live" ping for the student app: posts a Realtime broadcast
  /// event on [channelName] so a subscribed student refetches immediately
  /// instead of waiting for its next poll. Failures are ignored - polling
  /// remains the source of truth.
  Future<void> broadcast(String channelName, String event) async {
    try {
      await _client.channel(channelName).sendBroadcastMessage(event: event, payload: const {});
    } catch (_) {}
  }

  // ── Push notifications ───────────────────────────────────────────────────

  Future<void> registerPushToken(String fcmToken) async {
    await _client.rpc('register_teacher_push_token', params: {
      'p_fcm_token': fcmToken,
      'p_platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  Future<void> unregisterPushToken(String fcmToken) async {
    await _client.rpc('unregister_push_token', params: {'p_fcm_token': fcmToken});
  }
}
