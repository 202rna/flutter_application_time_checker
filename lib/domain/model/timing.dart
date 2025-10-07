import 'package:flutter_application_time_checker/domain/model/db_model.dart';

class Timing implements DbModel {
  @override
  final int? id;
  final DateTime date;
  final String time;
  final String? description;
  final int unitId;

  const Timing({
    this.id,
    required this.date,
    required this.time,
    this.description,
    required this.unitId,
  });

  factory Timing.fromMap(Map<String, dynamic> map) => _$GroupFromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(), // DateTime в строку
      'time': time, // Duration в секунды (или другой формат)
      'notes': description,
      'unit_id': unitId,
    };
  }
}

Timing _$GroupFromMap(Map<String, dynamic> map) => Timing(
      id: map['id'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      description: map['notes'],
      unitId: map['unit_id'],
    );
