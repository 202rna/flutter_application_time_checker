import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/presentation/page/group_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
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
        title: const Text('Добавить Unit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Название Unit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Добавить'),
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

  Future<void> _deleteUnit(int? id) async {
    if (id == null) return; // Если id null, не удаляем
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить Unit?'),
        content: const Text(
            'Это действие нельзя отменить. Удалить Unit и все связанные Groups и Timings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final unit = units[id.toString()];
        if (unit != null) {
          await DB.instance.delete<Unit>(unit);
          _loadUnits();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unit удалён')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Units')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
      ),
      body: units.isEmpty
          ? const Center(child: Text('Нет записей'))
          : ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unitKey = units.keys.elementAt(index);
                final unit = units[unitKey]!;
                return ListTile(
                  title: Text(unit.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUnit(unit.id),
                    tooltip: 'Удалить Unit',
                  ),
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
        tooltip: 'Добавить Unit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
