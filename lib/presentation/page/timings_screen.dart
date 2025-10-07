import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/domain/model/timing.dart';

class TimingsScreen extends StatefulWidget {
  final Group group;

  const TimingsScreen({super.key, required this.group});

  @override
  TimingsScreenState createState() => TimingsScreenState();
}

class TimingsScreenState extends State<TimingsScreen> {
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
    final TextEditingController timeControllerMM = TextEditingController();
    final TextEditingController timeControllerSS = TextEditingController();
    final TextEditingController timeControllerMMM = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Добавить Timing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: timeControllerMM,
                      decoration: const InputDecoration(labelText: 'MM'),
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: timeControllerSS,
                      decoration: const InputDecoration(labelText: 'SS'),
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: timeControllerMMM,
                      decoration: const InputDecoration(labelText: 'mmm'),
                      maxLength: 3,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Описание (опционально)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (timeControllerMM.text.isEmpty) timeControllerMM.text = '00';
                if (timeControllerSS.text.isEmpty) timeControllerSS.text = '00';
                if (timeControllerMMM.text.isEmpty) {
                  timeControllerMMM.text = '000';
                }

                Navigator.of(context).pop({
                  'date': DateTime.now(),
                  'time':
                      '${timeControllerMM.text}:${timeControllerSS.text}:${timeControllerMMM.text}',
                  'description': descriptionController.text,
                });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      );

      dateController.dispose();
      timeControllerMM.dispose();
      timeControllerSS.dispose();
      timeControllerMMM.dispose();
      descriptionController.dispose();

      if (result != null) {
        final newTiming = Timing(
          id: null,
          date: result['date'] as DateTime,
          time: result['time'] as String,
          description: (result['description'] as String).isNotEmpty
              ? result['description'] as String
              : null,
          groupId: widget.group.id,
        );
        await DB.instance.insert<Timing>(newTiming);
        _loadTimings(); // Перезагрузка
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteTiming(int? id) async {
    if (id == null) return; // Если id null, не удаляем
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить Timing?'),
        content: const Text('Это действие нельзя отменить.'),
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
        final timing = timings[id.toString()];
        if (timing != null) {
          await DB.instance.delete<Timing>(timing);
          _loadTimings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Timing удалён')),
            );
          }
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
        appBar: AppBar(title: Text('Время для ${widget.group.name}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Время для ${widget.group.name}'),
      ),
      body: timings.isEmpty
          ? const Center(child: Text('Нет записей'))
          : ListView.builder(
              itemCount: timings.length,
              itemBuilder: (context, index) {
                final timingKey = timings.keys.elementAt(index);
                final timing = timings[timingKey]!;
                return ListTile(
                  title: Text(
                      'Дата: ${timing.date.toLocal().toString().split(' ')[0]}, Время: ${timing.time}'),
                  subtitle: Text(timing.description ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTiming(timing.id),
                    tooltip: 'Удалить Timing',
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTiming,
        child: const Icon(Icons.add),
        tooltip: 'Добавить Timing',
      ),
    );
  }
}
