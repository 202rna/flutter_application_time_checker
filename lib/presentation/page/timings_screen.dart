import 'package:flutter/material.dart';
import 'package:flutter_application_time_checker/data/datasources/database.dart';
import 'package:flutter_application_time_checker/domain/model/group.dart';
import 'package:flutter_application_time_checker/domain/model/timing.dart';
import 'package:flutter_application_time_checker/presentation/widget/gradient_app_bar.dart';
import 'package:flutter_application_time_checker/presentation/widget/line_chart.dart';
import 'package:async/async.dart'; // Добавьте этот импорт для CancelableOperation

class TimingsScreen extends StatefulWidget {
  final Group group;

  const TimingsScreen({super.key, required this.group});

  @override
  TimingsScreenState createState() => TimingsScreenState();
}

class TimingsScreenState extends State<TimingsScreen> {
  late Map<String, Timing> timings = {};
  bool isLoading = true;
  CancelableOperation<void>? _loadOperation; // Для отмены _loadTimings
  CancelableOperation<void>? _addOperation; // Для отмены _addTiming
  CancelableOperation<void>? _deleteOperation; // Для отмены _deleteTiming

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  @override
  void dispose() {
    _loadOperation?.cancel(); // Отменяем загрузку
    _addOperation?.cancel(); // Отменяем добавление
    _deleteOperation?.cancel(); // Отменяем удаление
    super.dispose();
  }

  Future<void> _loadTimings() async {
    debugPrint('Start _loadTimings'); // Для отладки: проверьте логи
    _loadOperation = CancelableOperation.fromFuture(
      () async {
        try {
          final timingsIterable = await DB.instance.getAll<Timing>();
          timings = Map.fromIterable(
            timingsIterable.where((t) => (t).groupId == widget.group.id),
            key: (t) => (t as Timing).id.toString(),
          );
          if (!mounted) return; // Проверка перед setState
          setState(() {
            isLoading = false;
          });
          debugPrint('_loadTimings success'); // Для отладки
        } catch (e) {
          if (!mounted) return; // Проверка перед setState
          setState(() {
            isLoading = false;
          });
          debugPrint('_loadTimings error: $e'); // Для отладки
        }
      }(),
      onCancel: () => debugPrint('_loadTimings cancelled'),
    );
    try {
      await _loadOperation!.value;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      debugPrint('_loadTimings error: $e');
    }
  }

  Future<void> _addTiming() async {
    debugPrint('Start _addTiming'); // Для отладки
    final TextEditingController timeControllerMM = TextEditingController();
    final TextEditingController timeControllerSS = TextEditingController();
    final TextEditingController timeControllerMMM = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    _addOperation = CancelableOperation.fromFuture(
      () async {
        try {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Добавить время'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeControllerMM,
                          decoration: const InputDecoration(labelText: 'MM'),
                          maxLength: 10,
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
                    decoration: const InputDecoration(labelText: 'Заметки'),
                  ),
                ],
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
                      onPressed: () {
                        if (timeControllerMM.text.isNotEmpty ||
                            timeControllerSS.text.isNotEmpty ||
                            timeControllerMMM.text.isNotEmpty) {
                          if (timeControllerMM.text.isEmpty) {
                            timeControllerMM.text = '00';
                          }
                          if (timeControllerSS.text.isEmpty) {
                            timeControllerSS.text = '00';
                          }
                          if (timeControllerMMM.text.isEmpty) {
                            timeControllerMMM.text = '000';
                          }

                          Navigator.of(context).pop({
                            'date': DateTime.now(),
                            'time':
                                '${timeControllerMM.text}:${timeControllerSS.text}:${timeControllerMMM.text}',
                            'description': descriptionController.text,
                          });
                        }
                      },
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
              ],
            ),
          );

          // Контроллеры dispose не нужны здесь — они локальные и уничтожаются автоматически

          if (result != null && mounted) {
            // Проверка mounted перед продолжением
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
            if (mounted) {
              // Дополнительная проверка перед _loadTimings
              _loadTimings(); // Перезагрузка
            }
          }
          debugPrint('_addTiming completed'); // Для отладки
        } catch (e) {
          if (mounted) {
            // Проверка перед показом SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: $e')),
            );
          }
          debugPrint('_addTiming error: $e'); // Для отладки
        }
      }(),
      onCancel: () => debugPrint('_addTiming cancelled'),
    );

    await _addOperation!.value;
  }

  Future<void> _deleteTiming(int? id) async {
    if (id == null) return; // Если id null, не удаляем
    _deleteOperation = CancelableOperation.fromFuture(
      () async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить время ?'),
            content: const Text('Это действие нельзя отменить'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          try {
            final timing = timings[id.toString()];
            if (timing != null) {
              await DB.instance.delete<Timing>(timing);
              if (mounted) {
                _loadTimings();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Время удалено')),
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
      }(),
      onCancel: () => debugPrint('_deleteTiming cancelled'),
    );

    await _deleteOperation!.value;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: GradientAppBar(title: widget.group.name),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                offset: Offset(0, 4),
                blurRadius: 3,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.group.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(252, 246, 243, 174),
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: true,
            actions: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 169, 255, 77),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            buildTimingChartScreen(timings.values.toList()),
                      ),
                    );
                  },
                  child: const Text(
                    'График',
                    style: TextStyle(
                      fontSize: 15,
                      fontVariations: [FontVariation('wght', 500)],
                      fontFamily: 'Nunito',
                      color: Color.fromARGB(255, 2, 5, 136),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: timings.isEmpty
          ? const Center(child: Text('Нет записей'))
          : ListView.builder(
              itemCount: timings.length,
              itemBuilder: (context, index) {
                // Получаем перевернутый список ключей (последний добавленный — первый)
                final reversedKeys = timings.keys.toList().reversed.toList();
                final timingKey = reversedKeys[index];
                final timing = timings[timingKey]!;
                return ListTile(
                  title: Wrap(
                    spacing: 18.0,
                    children: [
                      Text(
                          'Дата: ${timing.date.toLocal().toString().split(' ')[0]}'),
                      Text("Время: ${timing.time}"),
                    ],
                  ),
                  subtitle: Text(timing.description ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTiming(timing.id),
                    tooltip: 'Удалить время',
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTiming,
        tooltip: 'Добавить время',
        child: const Icon(Icons.add),
      ),
    );
  }
}
