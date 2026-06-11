import '../core/supabase_config.dart';
import '../state/realtime_list.dart';
import 'models.dart';

class DayOption {
  const DayOption(this.value, this.label);
  final int value;
  final String label;
}

const List<DayOption> daysOfWeek = [
  DayOption(1, 'Pazartesi'),
  DayOption(2, 'Salı'),
  DayOption(3, 'Çarşamba'),
  DayOption(4, 'Perşembe'),
  DayOption(5, 'Cuma'),
  DayOption(6, 'Cumartesi'),
  DayOption(7, 'Pazar'),
];

const List<int> periods = [1, 2, 3, 4, 5, 6, 7, 8];

/// Dart's [DateTime.weekday] is already 1 (Monday) .. 7 (Sunday), matching the
/// `day_of_week` convention used by `schedule_entries`.
int isoDayOfWeek(DateTime date) => date.weekday;

/// Realtime weekly schedule for the current user, with an [setEntry] helper to
/// create/update/delete a single period's subject.
class ScheduleController extends RealtimeListController<ScheduleEntry> {
  ScheduleController(this.userId)
      : super(
          table: 'schedule_entries',
          fromJson: ScheduleEntry.fromJson,
          match: {'user_id': userId},
          compare: (a, b) => a.periodNumber.compareTo(b.periodNumber),
        );

  final String userId;

  Future<Object?> setEntry(int dayOfWeek, int periodNumber, String subjectName) async {
    final trimmed = subjectName.trim();
    try {
      if (trimmed.isEmpty) {
        await supabase
            .from('schedule_entries')
            .delete()
            .eq('user_id', userId)
            .eq('day_of_week', dayOfWeek)
            .eq('period_number', periodNumber);
        return null;
      }
      await supabase.from('schedule_entries').upsert(
        {
          'user_id': userId,
          'day_of_week': dayOfWeek,
          'period_number': periodNumber,
          'subject_name': trimmed,
        },
        onConflict: 'user_id,day_of_week,period_number',
      );
      return null;
    } catch (e) {
      return e;
    }
  }
}
