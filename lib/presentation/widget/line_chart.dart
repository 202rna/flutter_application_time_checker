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
    return minutes * 60.0 + seconds + (milliseconds / 1000.0);
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

String _formatDate(DateTime date) {
  return DateFormat('dd.MM').format(date);
}

Widget buildTimingChartScreen(List<Timing> timings) {
  final sortedTimings = List<Timing>.from(timings)
    ..sort((a, b) => a.date.compareTo(b.date));

  if (sortedTimings.isEmpty) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'График',
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Нет данных для графика',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }

  final spots = <FlSpot>[];
  final dateLabels = <String>[];
  double maxY = 0.0; // Инициализируем с 0.0, чтобы корректно считать максимум
  final uniqueY = <double>{};
  final secondsList = <double>[]; // Список секунд для расчёта статистики

  for (int i = 0; i < sortedTimings.length; i++) {
    final timing = sortedTimings[i];
    final seconds = _timeToSeconds(timing.time);
    spots.add(FlSpot(i.toDouble(), seconds));
    dateLabels.add(_formatDate(timing.date));
    uniqueY.add(seconds);
    secondsList.add(seconds);
    if (seconds > maxY) maxY = seconds;
  }

  // MaxY с буфером (добавляем 10 сек для отступа сверху, если maxY > 0)
  maxY = maxY > 0
      ? maxY + 10
      : 10; // Если все 0, установим минимум 10 для видимости

  // Расчёт статистики
  final best = secondsList.reduce((a, b) => a < b ? a : b);
  final worst = secondsList.reduce((a, b) => a > b ? a : b);
  final average = secondsList.isNotEmpty
      ? secondsList.reduce((a, b) => a + b) / secondsList.length
      : 0.0;

  return Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Text(
            'График',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 28,
              fontVariations: [FontVariation('wght', 900)],
              color: Color.fromRGBO(231, 236, 80, 1),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            '(по датам)',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontVariations: [FontVariation('wght', 900)],
              color: Color.fromRGBO(194, 196, 144, 1),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 300, // Высота графика
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    //horizontalInterval: 60,
                    verticalInterval: 1,
                  ),
                  // Заголовки осей
                  titlesData: FlTitlesData(
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
                        interval: dateLabels.length / 3,
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.spotIndex;
                          final originalTime = sortedTimings[index].time;
                          final originalDate = dateLabels[index];
                          return LineTooltipItem(
                            '$originalTime\n $originalDate',
                            const TextStyle(color: Colors.white, fontSize: 15),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  // Линия графика
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: false,
                      ),
                      dotData: FlDotData(
                        show: true, // Показывать точки
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: const Color.fromARGB(255, 194, 227, 30),
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'MIN: ${_secondsToTimeString(best)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'MAX: ${_secondsToTimeString(worst)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ),
                    Text(
                      'AVG: ${_secondsToTimeString(average)}',
                      style: const TextStyle(
                          fontSize: 14,
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
    ),
  );
}
