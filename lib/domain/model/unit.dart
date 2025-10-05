import 'package:flutter_application_time_checker/domain/model/db_model.dart';

class Unit implements DbModel {
  final int? id;
  final String name;

  const Unit({this.id, required this.name});

  factory Unit.fromMap(Map<String, dynamic> map) => _$GroupFromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }
}

Unit _$GroupFromMap(Map<String, dynamic> map) => Unit(
      id: map['id'],
      name: map['name'],
    );
