import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthTrendChart extends StatelessWidget {
  final String title;
  final double previousValue;
  final double currentValue;
  final String unit;
  final Color color;

  const HealthTrendChart({
    Key? key,
    required this.title,
    required this.previousValue,
    required this.currentValue,
    required this.unit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 1,
                minY: (previousValue < currentValue ? previousValue : currentValue) * 0.9,
                maxY: (previousValue > currentValue ? previousValue : currentValue) * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, previousValue),
                      FlSpot(1, currentValue),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previous',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '$previousValue $unit',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Current',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '$currentValue $unit',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
