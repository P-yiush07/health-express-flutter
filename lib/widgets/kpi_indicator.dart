import 'package:flutter/material.dart';
import 'health_trend_chart.dart';

class KpiIndicator extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? previousValue;

  const KpiIndicator({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.previousValue,
  });

  void _showTrendChart(BuildContext context) {
    // Skip showing chart if current value is N/A
    if (value.toLowerCase() == 'n/a') return;

    // Parse values for the chart
    double? currentVal;
    double? previousVal;

    if (title == 'Blood Pressure') {
      // Handle blood pressure special case
      final current = value.replaceAll(RegExp(r'[^\d/]'), '').split('/');
      final previous = previousValue?.replaceAll(RegExp(r'[^\d/]'), '').split('/');
      
      if (current.length == 2) {
        currentVal = double.tryParse(current[0]);
      }
      if (previous != null && previous.length == 2) {
        previousVal = double.tryParse(previous[0]);
      }
    } else {
      // Handle regular numeric values
      currentVal = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      previousVal = previousValue != null ? 
        double.tryParse(previousValue!.replaceAll(RegExp(r'[^\d.]'), '')) : null;
    }

    // Show chart if we have at least the current value
    if (currentVal != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: HealthTrendChart(
                    title: title,
                    currentValue: currentVal!,
                    previousValue: (previousVal ?? currentVal)!,
                    unit: unit,
                    color: color,
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          previousVal != null 
                            ? '${previousVal.toStringAsFixed(1)} $unit'
                            : 'No previous data',
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentVal.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
    } else {
      // Show error message if we can't parse the current value
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to display chart: Invalid value format'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String cleanValue = value.trim();
    
    // Check for N/A first
    if (cleanValue.toLowerCase() == 'n/a') {
      cleanValue = 'N/A';
      return GestureDetector(
        onTap: () => _showTrendChart(context),
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
              Text(
                'N/A',
                style: TextStyle(
                  color: color, 
                  fontSize: 30, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Special handling for different metrics
    if (title == 'Blood Pressure') {
      // Keep only numbers and slash for Blood Pressure
      cleanValue = value.replaceAll(RegExp(r'[^\d/]'), '');
      return GestureDetector(
        onTap: () => _showTrendChart(context),
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
                      cleanValue,
                      style: TextStyle(
                        color: color, 
                        fontSize: 30, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'mmHg',
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
    } else {
      // For all other metrics, clean the value of any existing units
      cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '').trim();
    }

    // Modified container to be tappable
    return GestureDetector(
      onTap: () => _showTrendChart(context),
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
                    cleanValue,
                    style: TextStyle(
                      color: color, 
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty && cleanValue.toLowerCase() != 'n/a') ...[
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        color: color, 
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

