import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/domain/model/timing.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/domain/model/db_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DB.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final Unit unit;
  late int unitId; // Изменено на int, так как мы ждём завершения
  late Map<String, Unit> unitAll;
  bool isLoading = true; // Флаг загрузки

  @override
  void initState() {
    super.initState();
    unitAll = {}; // Инициализация пустой карты
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      unit = Unit(name: 'Example Unit');
      final id = await DB.instance.insert<Unit>(unit); // Ждём вставки
      unitId = id; // Присваиваем int

      // Получаем все Unit-ы (включая новый, так как insert завершён)
      final unitsIterable = await DB.instance.getAll<Unit>();
      unitAll = Map.fromIterable(unitsIterable,
          key: (u) =>
              (u as Unit).id.toString()); // Преобразуем Iterable в Map по id

      setState(() {
        isLoading = false; // Загрузка завершена
      });
    } catch (e) {
      // Обработка ошибок (например, логирование или показ Snackbar)
      print('Ошибка инициализации: $e');
      setState(() {
        isLoading = false; // Даже при ошибке прекращаем загрузку
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Column(
        children: [
          Text('Unit ID: $unitId'),
          Text('Все units: ${unitAll.length} шт.'),
          // Пример отображения: ListView с unitAll
          Expanded(
            child: ListView.builder(
              itemCount: unitAll.length,
              itemBuilder: (context, index) {
                final unitKey = unitAll.keys.elementAt(index);
                final unit = unitAll[unitKey]!;
                return ListTile(
                  title: Text(unit.name),
                  subtitle: Text('ID: $unitKey'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
