import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/domain/model/timing.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Map<String, Unit> units = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final unitsIterable = await DB.instance.getAll<Unit>();
      units = Map.fromIterable(unitsIterable,
          key: (u) => (u as Unit).id.toString());
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addUnit() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить Unit'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Название Unit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Добавить'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final newUnit = Unit(name: name);
      await DB.instance.insert<Unit>(newUnit);
      _loadUnits(); // Перезагрузка списка
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Units')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
      ),
      body: units.isEmpty
          ? Center(child: Text('Нет units'))
          : ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unitKey = units.keys.elementAt(index);
                final unit = units[unitKey]!;
                return ListTile(
                  title: Text(unit.name),
                  onTap: () {
                    // Переход к группам для этого unit
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupsScreen(unit: unit),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUnit,
        child: Icon(Icons.add),
        tooltip: 'Добавить Unit',
      ),
    );
  }
}

// Экран групп для выбранного unit
class GroupsScreen extends StatefulWidget {
  final Unit unit;

  const GroupsScreen({super.key, required this.unit});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Map<String, Group> groups = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      // Предполагаем, что getAll<Group>() возвращает все группы, и мы фильтруем по unitId
      // Если Group имеет поле unitId (int или String), фильтруем
      final groupsIterable = await DB.instance.getAll<Group>();
      groups = Map.fromIterable(
        groupsIterable.where((g) =>
            (g as Group).unitId ==
            widget.unit.id), // Предполагаем, что Group имеет unitId
        key: (g) => (g as Group).id.toString(),
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки групп: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addGroup() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить Group'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Название Group'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Добавить'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final newGroup = Group(name: name, unitId: widget.unit.id);
      await DB.instance.insert<Group>(newGroup);
      _loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Группы для ${widget.unit.name}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Группы для ${widget.unit.name}'),
      ),
      body: groups.isEmpty
          ? Center(child: Text('Нет групп'))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final groupKey = groups.keys.elementAt(index);
                final group = groups[groupKey]!;
                return ListTile(
                  title: Text(group.name),
                  onTap: () {
                    // Переход к timing для этой группы
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimingsScreen(group: group),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        child: Icon(Icons.add),
        tooltip: 'Добавить Group',
      ),
    );
  }
}

// Экран timing для выбранной группы
class TimingsScreen extends StatefulWidget {
  final Group group;

  const TimingsScreen({super.key, required this.group});

  @override
  _TimingsScreenState createState() => _TimingsScreenState();
}

class _TimingsScreenState extends State<TimingsScreen> {
  late Map<String, Timing> timings = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  Future<void> _loadTimings() async {
    try {
      // Фильтруем по groupId, предполагая, что Timing имеет поле groupId (FK на Group)
      final timingsIterable = await DB.instance.getAll<Timing>();
      timings = Map.fromIterable(
        timingsIterable.where((t) =>
            (t as Timing).groupId ==
            widget.group
                .id), // Исправлено: groupId вместо unitId, и widget.group.id
        key: (t) => (t as Timing).id.toString(),
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки timing: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addTiming() async {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    DateTime? selectedDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить Timing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Дата (YYYY-MM-DD)'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  selectedDate = picked;
                  dateController.text = picked
                      .toIso8601String()
                      .split('T')
                      .first; // Формат YYYY-MM-DD
                }
              },
              readOnly: true,
            ),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                  labelText: 'Время (MM:SS:mmm, например 05:30:000)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Описание (опционально)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'date': selectedDate,
              'time': timeController.text,
              'description': descriptionController.text,
            }),
            child: Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null &&
        result['date'] != null &&
        result['time']!.isNotEmpty) {
      final newTiming = Timing(
        id: null, // Автогенерация в БД
        date: result['date'] as DateTime,
        time: result['time'] as String,
        description: (result['description'] as String).isNotEmpty
            ? result['description'] as String
            : null,
        groupId: widget.group.id,
      );
      await DB.instance.insert<Timing>(newTiming);
      _loadTimings(); // Перезагрузка списка
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Timing для ${widget.group.name}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Timing для ${widget.group.name}'),
      ),
      body: timings.isEmpty
          ? Center(child: Text('Нет timing'))
          : ListView.builder(
              itemCount: timings.length,
              itemBuilder: (context, index) {
                final timingKey = timings.keys.elementAt(index);
                final timing = timings[timingKey]!;
                return ListTile(
                  title: Text(
                      'Дата: ${timing.date.toLocal().toString().split(' ')[0]}, Время: ${timing.time}'),
                  subtitle: Text(timing.description ?? 'Без описания'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTiming,
        child: Icon(Icons.add),
        tooltip: 'Добавить Timing',
      ),
    );
  }
}
