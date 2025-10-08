import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/presentation/page/group_screen.dart';
import 'package:flutter_application_time_checker/presentation/widget/gradient_app_bar.dart';
import 'package:flutter_application_time_checker/presentation/widget/home_list.dart';

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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ФИО'),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final newUnit = Unit(name: name);
      await DB.instance.insert<Unit>(newUnit);
      _loadUnits();
    }
  }

  Future<void> _deleteUnit(int? id) async {
    if (id == null) return; // Если id null, не удаляем
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: const Text(
            'Это действие нельзя отменить. Удалить запись и все связанные группы и результаты ?'),
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
              const SnackBar(content: Text('Запись удалена')),
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
      appBar: const GradientAppBar(title: 'СПИСОК'),
      body: units.isEmpty
          ? const Center(
              child: Text(
              'Нет записей',
              style: TextStyle(
                fontSize: 16,
              ),
            ))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 5.0),
                  SportyList(
                    items: units.values
                        .map((unit) =>
                            ListItem(id: unit.id.toString(), name: unit.name))
                        .toList(),
                    onItemTap: (item) {
                      final unit = units[item.id];
                      if (unit != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupsScreen(unit: unit),
                          ),
                        );
                      }
                    },
                    onDelete: (id) => _deleteUnit(int.tryParse(id)),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUnit,
        backgroundColor: const Color.fromARGB(0, 204, 23, 23),
        elevation: 8,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: Color.fromARGB(255, 236, 15, 15),
            size: 28,
          ),
        ),
      ),
    );
  }
}
