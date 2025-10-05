import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_application_time_checker/domain/model/db_model.dart';

class Group implements DbModel {
  @override
  final int id;
  final String name;

  const Group({required this.id, required this.name});

  factory Group.fromMap(Map<String, dynamic> map) => _$GroupFromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }
}

Group _$GroupFromMap(Map<String, dynamic> map) => Group(
      id: map['id'],
      name: map['name'],
    );
