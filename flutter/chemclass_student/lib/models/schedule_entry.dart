/// A single "Ders Programı" (personal class schedule) entry. Stored locally
/// only (shared_preferences) — there is no web-app equivalent.
class ScheduleEntry {
  String id;
  int day; // 0 = Pazartesi .. 6 = Pazar
  String startTime; // 'HH:mm'
  String endTime; // 'HH:mm'
  String subject;
  String room;
  int color;

  ScheduleEntry({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room = '',
    this.color = 0,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id']?.toString() ?? '',
        day: (json['day'] as num?)?.toInt() ?? 0,
        startTime: json['startTime']?.toString() ?? '08:00',
        endTime: json['endTime']?.toString() ?? '08:40',
        subject: json['subject']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        color: (json['color'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'room': room,
        'color': color,
      };
}
