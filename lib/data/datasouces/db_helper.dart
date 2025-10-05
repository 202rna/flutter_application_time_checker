import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_application_time_checker/domain/model/timing.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/domain/model/db_model.dart';

class DB {
  DB._(); // Приватный конструктор
  static final DB instance = DB._(); // экземпляр с которым будем работать
  static late Database _db; // “интерфейс” для работы с sqflite
  static bool _isInitialized = false;

  Future init() async {
    if (!_isInitialized) {
      var databasePath =
          await getDatabasesPath(); // получение дефолтной папки для сохранения файла БД

      var path = join(databasePath, "db_v1.0.0.db");

      _db = await openDatabase(path, version: 1, onCreate: _createDB);
      _isInitialized = true;
    }
  }
}

Future _createDB(Database db, int version) async {
  var dbInitScript = await rootBundle.loadString('assets/db_init.sql');

  dbInitScript.split(';').forEach((element) async {
    if (element.isNotEmpty) {
      await db.execute(element);
    }
  });
}

final _factories = <Type, Function(Map<String, dynamic> map)>{
  Group: (map) => Group.fromMap(map),
  Timing: (map) => Timing.fromMap(map),
  Unit: (map) => Unit.fromMap(map),
};

String _dbName(Type type) {
  if (type == DbModel) {
    throw Exception("Type is required");
  }
  return "${(type).toString()}";
}
