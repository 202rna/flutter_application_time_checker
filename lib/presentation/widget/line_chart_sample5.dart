import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Для форматирования дат (добавьте в pubspec.yaml: intl: ^0.18.1)
import 'package:flutter_application_time_checker/domain/model/timing.dart';

// Функция для конвертации времени "MM:SS:mmm" в секунды (миллисекунды преобразуем в доли секунды)
double _timeToSeconds(String time) {
  final parts = time.split(':');
  if (parts.length == 3) {
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    final milliseconds = int.tryParse(parts[2]) ?? 0;
    return minutes * 60.0 +
        seconds +
        (milliseconds / 1000.0); // Возвращаем double для точности
  }
  return 0.0;
}

// Функция для форматирования секунд обратно в "MM:SS:mmm"
String _secondsToTimeString(double seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = ((seconds % 60).toInt()).toString().padLeft(2, '0');
  final millis = ((seconds % 1) * 1000).toInt().toString().padLeft(3, '0');
  return '$minutes:$secs:$millis';
}

// Функция для форматирования даты в "dd.MM"
String _formatDate(DateTime date) {
  return DateFormat('dd.MM').format(date);
}

// Основная функция для экрана графика
Widget buildTimingChartScreen(List<Timing> timings) {
  // Сортируем по дате (ascending)
  final sortedTimings = List<Timing>.from(timings)
    ..sort((a, b) => a.date.compareTo(b.date));

  // Если нет данных
  if (sortedTimings.isEmpty) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График таймингов'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Нет данных для графика',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }

  // Создаём точки данных: X = индекс (для равномерных интервалов), Y = секунды
  final spots = <FlSpot>[];
  final dateLabels = <String>[];
  double maxY = 0.0; // Инициализируем с 0.0, чтобы корректно считать максимум
  final uniqueY = <double>{}; // Множество уникальных Y-значений для меток оси Y
  final secondsList = <double>[]; // Список секунд для расчёта статистики

  for (int i = 0; i < sortedTimings.length; i++) {
    final timing = sortedTimings[i];
    final seconds = _timeToSeconds(timing.time); // Теперь double
    spots.add(
        FlSpot(i.toDouble(), seconds)); // X: индекс (равномерный), Y: секунды
    dateLabels.add(_formatDate(timing.date)); // Метка даты
    uniqueY.add(seconds); // Добавляем в уникальные Y
    secondsList.add(seconds); // Для статистики
    if (seconds > maxY) maxY = seconds;
  }

  // MaxY с буфером (добавляем 10 сек для отступа сверху, если maxY > 0)
  maxY = maxY > 0
      ? maxY + 10
      : 10; // Если все 0, установим минимум 10 для видимости

  // Расчёт статистики
  final best = secondsList.reduce((a, b) => a < b ? a : b); // Минимальное время
  final worst =
      secondsList.reduce((a, b) => a > b ? a : b); // Максимальное время
  final average = secondsList.isNotEmpty
      ? secondsList.reduce((a, b) => a + b) / secondsList.length
      : 0.0; // Среднее время

  return Scaffold(
    appBar: AppBar(
      title: const Text('График таймингов'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 300, // Высота графика
            child: LineChart(
              LineChartData(
                // Сетка
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 60, // Интервал сетки по Y (каждые 60 сек)
                  verticalInterval: 1, // Интервал по X (каждый индекс)
                ),
                // Заголовки осей
                titlesData: FlTitlesData(
                  // Ось X (bottom): метки дат с равномерными интервалами
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dateLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateLabels[index],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1, // Равномерный интервал: каждый пункт
                      reservedSize: 30,
                    ),
                  ),
                  // Ось Y (left): метки в MM:SS:mmm только для значений, присутствующих на графике
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (uniqueY.contains(value)) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _secondsToTimeString(value),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black),
                            ),
                          );
                        }
                        return const SizedBox(); // Пусто, если значение не в данных
                      },
                      reservedSize: 50,
                    ),
                  ),
                  // Скрываем top и right
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                // Границы
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey),
                ),
                // Тултипы при касании точки: показывают оригинальное время MM:SS:mmm
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final originalTime =
                            sortedTimings[index].time; // Оригинальное время
                        return LineTooltipItem(
                          originalTime, // Показываем MM:SS:mmm
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                    //tooltipBgColor: Colors.blueAccent,
                  ),
                ),
                // Линия графика
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true, // Кривая линия для плавности
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: false, // Без заливки под линией
                    ),
                    dotData: FlDotData(
                      show: true, // Показывать точки
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                // Диапазоны осей
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Статистика под графиком
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'MIN: ${_secondsToTimeString(best)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'MAX: ${_secondsToTimeString(worst)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ),
                  Text(
                    'AVG: ${_secondsToTimeString(average)}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
