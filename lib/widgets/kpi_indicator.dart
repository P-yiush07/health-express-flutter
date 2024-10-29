import 'package:flutter/material.dart';
import 'health_trend_chart.dart';

class KpiIndicator extends StatelessWidget {
  final String title;
  final String value;
  final String? previousValue;
  final String unit;
  final IconData icon;
  final Color color;

  const KpiIndicator({
    super.key,
    required this.title,
    required this.value,
    this.previousValue,
    required this.unit,
    required this.icon,
    required this.color,
  });

  void _showChartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double currentVal;
        double prevVal;

        if (title.toLowerCase().contains('blood pressure')) {
          final currentParts = value.split('/');
          final prevParts = (previousValue ?? value).split('/');
          // Use systolic (upper number) for the chart
          currentVal = double.parse(currentParts[0].trim());
          prevVal = double.parse(prevParts[0].trim());
        } else {
          currentVal = double.tryParse(value) ?? 0;
          prevVal = double.tryParse(previousValue ?? value) ?? 0;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(20),
            ),
            child: HealthTrendChart(
              title: title,
              previousValue: prevVal,
              currentValue: currentVal,
              unit: unit,
              color: color,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showChartDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.toLowerCase().contains(unit.toLowerCase()) 
                        ? value.replaceAll(RegExp(unit, caseSensitive: false), '').trim()
                        : value,
                    style: TextStyle(
                      color: color, 
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color, 
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

