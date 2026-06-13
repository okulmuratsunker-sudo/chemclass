/// Mirrors a row of the `students` table.
class Student {
  final String id;
  final String name;
  final double hourlyRate;

  const Student({
    required this.id,
    required this.name,
    required this.hourlyRate,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'hourly_rate': hourlyRate,
      };

  Student copyWith({String? id, String? name, double? hourlyRate}) => Student(
        id: id ?? this.id,
        name: name ?? this.name,
        hourlyRate: hourlyRate ?? this.hourlyRate,
      );
}
