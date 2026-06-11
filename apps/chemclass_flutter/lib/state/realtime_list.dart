import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../data/models.dart';

/// Generic realtime-backed list, mirroring the `useRealtimeList` hook from the
/// previous React Native app: fetches the initial rows, then keeps them in
/// sync via a Supabase Realtime postgres_changes subscription.
class RealtimeListController<T extends Identifiable> extends ChangeNotifier {
  RealtimeListController({
    required this.table,
    required this.fromJson,
    this.match = const {},
    this.compare,
  }) {
    _load();
    _subscribe();
  }

  final String table;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> match;
  final int Function(T a, T b)? compare;

  List<T> items = [];
  bool loading = true;
  Object? error;

  RealtimeChannel? _channel;

  Future<void> _load() async {
    try {
      PostgrestFilterBuilder query = supabase.from(table).select();
      for (final entry in match.entries) {
        query = query.eq(entry.key, entry.value);
      }
      final data = await query;
      items = (data as List).map((row) => fromJson(row as Map<String, dynamic>)).toList();
      _sort();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refetch() => _load();

  void _sort() {
    final cmp = compare;
    if (cmp != null) items.sort(cmp);
  }

  bool _matchesFilter(Map<String, dynamic> row) {
    for (final entry in match.entries) {
      if (row[entry.key]?.toString() != entry.value?.toString()) return false;
    }
    return true;
  }

  void _subscribe() {
    final channel = supabase.channel('realtime:$table:${match.values.join(',')}:${identityHashCode(this)}');

    PostgresChangeFilter? filter;
    if (match.length == 1) {
      final entry = match.entries.first;
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: entry.key,
        value: entry.value,
      );
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: filter,
      callback: _handleChange,
    );
    channel.subscribe();
    _channel = channel;
  }

  void _handleChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        {
          final row = payload.newRecord;
          if (!_matchesFilter(row)) return;
          final item = fromJson(row);
          if (items.any((e) => e.id == item.id)) return;
          items.add(item);
          _sort();
          break;
        }
      case PostgresChangeEvent.update:
        {
          final row = payload.newRecord;
          final item = fromJson(row);
          if (!_matchesFilter(row)) {
            items.removeWhere((e) => e.id == item.id);
          } else {
            final idx = items.indexWhere((e) => e.id == item.id);
            if (idx >= 0) {
              items[idx] = item;
            } else {
              items.add(item);
            }
            _sort();
          }
          break;
        }
      case PostgresChangeEvent.delete:
        {
          final oldRow = payload.oldRecord;
          final id = oldRow['id']?.toString();
          if (id != null) items.removeWhere((e) => e.id == id);
          break;
        }
      default:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }
}
