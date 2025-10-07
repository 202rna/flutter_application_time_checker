import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/unit.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/presentation/page/timings_screen.dart';

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
        groupsIterable.where((g) => (g as Group).unitId == widget.unit.id),
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

  Future<void> _deleteGroup(int? id) async {
    if (id == null) return; // Если id null, не удаляем
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить Group?'),
        content: Text(
            'Это действие нельзя отменить. Удалить Group и все связанные Timings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Удалить'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group удалён')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
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
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGroup(group.id),
                    tooltip: 'Удалить Group',
                  ),
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
