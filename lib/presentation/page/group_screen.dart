import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/presentation/page/timings_screen.dart';
import 'package:flutter_application_time_checker/presentation/widget/gradient_app_bar.dart';

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
      // getAll<Group>() возвращает все группы, и мы фильтруем по unitId
      // Если Group имеет поле unitId (int или String), фильтруем
      final groupsIterable = await DB.instance.getAll<Group>();
      groups = Map.fromIterable(
        groupsIterable.where((g) => (g).unitId == widget.unit.id),
        key: (g) => (g as Group).id.toString(),
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
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
        //title: const Text('Добавить группу'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Название группы'),
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
      final newGroup = Group(name: name, unitId: widget.unit.id);
      await DB.instance.insert<Group>(newGroup);
      _loadGroups();
    }
  }

  Future<void> _deleteGroup(int? id) async {
    if (id == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: const Text('Удалить группу и все связанные результаты ?'),
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
        final group = groups[id.toString()];
        if (group != null) {
          await DB.instance.delete<Group>(group);
          _loadGroups();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Группа удалёна')),
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
        appBar: GradientAppBar(
          title: widget.unit.name,
          fs: 20,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.unit.name,
        fs: 20,
      ),
      body: groups.isEmpty
          ? const Center(child: Text('Нет групп'))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final groupKey = groups.keys.elementAt(index);
                final group = groups[groupKey]!;
                return ListTile(
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGroup(group.id),
                    tooltip: 'Удалить группу',
                  ),
                  onTap: () {
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
        tooltip: 'Добавить группу',
        child: const Icon(Icons.add),
      ),
    );
  }
}
