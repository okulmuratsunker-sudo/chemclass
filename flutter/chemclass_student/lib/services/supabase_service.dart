import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/realtime_channels.dart';

/// Wraps the anonymous Supabase RPC calls the student app needs. The
/// student app never creates a Supabase Auth session — `student_login`
/// returns an opaque session token (stored locally) that every other call
/// is authenticated with, mirroring the SECURITY DEFINER functions defined
/// in `supabase/student_app_setup.sql`.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Returns `{token, student_id, student_name, class_name, score, teacher_id}`.
  /// Throws a [PostgrestException] with message `INVALID_CODE` /
  /// `INVALID_NUMBER` on failure.
  Future<Map<String, dynamic>> studentLogin(String code, String no) async {
    final rows = await _client.rpc('student_login', params: {'p_code': code, 'p_no': no});
    final list = List<Map<String, dynamic>>.from(rows as List);
    return list.first;
  }

  /// Returns `{student, leaderboard, assignments, messages}`.
  Future<Map<String, dynamic>> getData(String token) async {
    final result = await _client.rpc('student_get_data', params: {'p_token': token});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> sendMessage(String token, String body) async {
    await _client.rpc('student_send_message', params: {'p_token': token, 'p_body': body});
  }

  /// Subscribes to Realtime broadcast pings on [channelName] (sent by the
  /// teacher app when it sends a message/assignment) and calls [onPing] for
  /// any of them. Best-effort "live" layer: if the broadcast never arrives,
  /// the regular poll still picks up new data.
  RealtimeChannel subscribeBroadcast(String channelName, void Function() onPing) {
    final channel = _client.channel(channelName);
    channel
        .onBroadcast(event: evtNewMessage, callback: (_) => onPing())
        .onBroadcast(event: evtNewAssignment, callback: (_) => onPing());
    channel.subscribe();
    return channel;
  }

  void removeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }

  // ── Push notifications ───────────────────────────────────────────────────

  Future<void> registerPushToken(String sessionToken, String fcmToken) async {
    await _client.rpc('register_student_push_token', params: {
      'p_token': sessionToken,
      'p_fcm_token': fcmToken,
      'p_platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  Future<void> unregisterPushToken(String fcmToken) async {
    await _client.rpc('unregister_push_token', params: {'p_fcm_token': fcmToken});
  }
}
