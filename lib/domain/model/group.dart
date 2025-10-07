import 'package:flutter_application_time_checker/domain/model/db_model.dart';

class Group implements DbModel {
  @override
  final int? id;
  final String name;
  final int? unitId;

  const Group({this.id, required this.name, required this.unitId});

  factory Group.fromMap(Map<String, dynamic> map) => _$GroupFromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'unitId': unitId,
    };
  }
}

Group _$GroupFromMap(Map<String, dynamic> map) => Group(
      id: map['id'],
      name: map['name'],
      unitId: map['unitId'],
    );
