import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import 'models.dart';

/// Looks up a board session id from a teacher-shared Tahta code. Works without auth (anon).
Future<({String? boardSessionId, Object? error})> redeemBoardCode(String code) async {
  try {
    final data = await supabase.rpc('redeem_board_code', params: {'p_code': code.trim()});
    return (boardSessionId: data as String?, error: null);
  } catch (e) {
    return (boardSessionId: null, error: e);
  }
}

/// Fetches the board session for a class and keeps its board_state in sync via Realtime.
class BoardController extends ChangeNotifier {
  BoardController(this.classId) {
    _init();
  }

  final String classId;
  BoardSession? session;
  BoardState? state;
  bool loading = true;
  Object? error;

  RealtimeChannel? _channel;

  Future<void> _init() async {
    try {
      final sessionData = await supabase.from('board_sessions').select().eq('class_id', classId).single();
      session = BoardSession.fromJson(sessionData);
      await _loadState();
      _subscribe();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadState() async {
    final sessionId = session?.id;
    if (sessionId == null) return;
    final data = await supabase.from('board_state').select().eq('board_session_id', sessionId).maybeSingle();
    state = data != null ? BoardState.fromJson(data) : null;
  }

  void _subscribe() {
    final sessionId = session?.id;
    if (sessionId == null) return;

    final channel = supabase.channel('realtime:board_state:$sessionId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'board_state',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'board_session_id', value: sessionId),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.delete) {
          state = null;
        } else {
          state = BoardState.fromJson(payload.newRecord);
        }
        notifyListeners();
      },
    );
    channel.subscribe();
    _channel = channel;
  }

  Future<Object?> updateState(String stateType, Map<String, dynamic> payload) async {
    final sessionId = session?.id;
    if (sessionId == null) return Exception('No board session');
    try {
      await supabase.from('board_state').update({
        'state_type': stateType,
        'payload': payload,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('board_session_id', sessionId);
      return null;
    } catch (e) {
      return e;
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }
}
