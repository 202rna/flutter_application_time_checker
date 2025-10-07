import 'dart:async';
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

      _db = await openDatabase(path,
          version: 1, onConfigure: _onConfigure, onCreate: _createDB);
      _isInitialized = true;
    }
  }

  _onConfigure(Database db) async {
    // Add support for cascade delete
    await db.execute("PRAGMA foreign_keys = ON");
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS [Group] (
      [id] INTEGER PRIMARY KEY AUTOINCREMENT,
      [groupName] TEXT NOT NULL,
      [unitId] INTEGER NOT NULL,
      FOREIGN KEY ([unitId]) REFERENCES [Unit]([id]) ON DELETE CASCADE,
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS [Unit] (
      [id] INTEGER PRIMARY KEY AUTOINCREMENT,
      [name] TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS [Timing] (
      [id] INTEGER PRIMARY KEY AUTOINCREMENT,
      [date] TEXT NOT NULL,
      [time] TEXT NOT NULL,
      [description] TEXT,
      [groupId] INTEGER NOT NULL,
      FOREIGN KEY ([groupId]) REFERENCES [Group]([id]) ON DELETE CASCADE
    )
  ''');
  }

  Future<int> insert<T extends DbModel>(T model) async => await _db.insert(
        _dbName(T), // Получаем имя рабочей таблицы
        model.toMap(), // Переводим наш объект в мапу для вставки
        conflictAlgorithm: null, // Что должно происходить при конфликте вставки
        nullColumnHack:
            null, // Что делать, если not null столбец приходит как null
      );

  Future<T?> get<T extends DbModel>(dynamic id) async {
    var res = await _db.query(
      _dbName(T),
      where:
          'id = ? ', // Прописываем в виде строки нужное нам условие и на месте сравниваемого значения ставим ‘?’
      whereArgs: [
        id
      ], // значения, передаваемые в этом массиве будут подставляться вместо ‘?’ в запросах. Порядок аргументов ВАЖЕН!
    );
    return res.isNotEmpty ? _factories[T]!(res.first) : null;
  }

  Future<Iterable<T>> getAll<T extends DbModel>({
    Map<String, Object?>? whereMap,
    int? take,
    int? skip,
  }) async {
    Iterable<Map<String, dynamic>> query;

    if (whereMap != null) {
      var whereBuilder = <String>[];
      var whereArgs = <dynamic>[];

      whereMap.forEach((key, value) {
        if (value is Iterable<dynamic>) {
          whereBuilder
              .add("$key IN (${List.filled(value.length, '?').join(',')})");
          whereArgs.addAll(value.map((e) => "$e"));
        } else {
          whereBuilder.add("$key = ?");
          whereArgs.add(value);
        }
      });

      query = await _db.query(_dbName(T),
          where: whereBuilder.join(' and '),
          whereArgs: whereArgs,
          offset: skip,
          limit: take);
    } else {
      query = await _db.query(
        _dbName(T),
        offset: skip,
        limit: take,
      );
    }

    var resList = query.map((e) => _factories[T]!(e)).cast<T>();

    return resList;
  }

  Future<int> update<T extends DbModel>(T model) async => _db.update(
        _dbName(T),
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );

  Future<int> delete<T extends DbModel>(T model) async => _db.delete(
        _dbName(T),
        where: 'id = ?',
        whereArgs: [model.id],
      );

  Future<int> cleanTable<T extends DbModel>() async =>
      await _db.delete(_dbName(T));

  Future<int> createUpdate<T extends DbModel>(T model) async {
    var dbItem = await get<T>(model.id);
    var res = dbItem == null ? insert(model) : update(model);
    return await res;
  }
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
  return (type).toString();
}
