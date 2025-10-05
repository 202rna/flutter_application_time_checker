import 'package:flutter_application_time_checker/domain/model/db_model.dart';


class Timing implements DbModel {
  final int id;
  final DateTime date;
  final Duration time;
  final String notes;
  final int unit_id;
  final int? group_id;

  const Timing(
      {required this.id,
      required this.date,
      required this.time,
      required this.notes,
      required this.unit_id,
      this.group_id});

  factory Timing.fromMap(Map<String, dynamic> map) => _$GroupFromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),  // DateTime в строку
      'time': time.inSeconds,  // Duration в секунды (или другой формат)
      'notes': notes,
      'unit_id': unit_id,
      'group_id': group_id,
    };
  }
}

Timing _$GroupFromMap(Map<String, dynamic> map) => Timing(
      id: map['id'],
      date: DateTime.parse(map['date']),
      time: Duration(seconds: map['time']),
      notes: map['notes'],
      unit_id: map['unit_id'],
      group_id: map['group_id'],
    );
