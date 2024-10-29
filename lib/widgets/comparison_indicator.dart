import 'package:flutter/material.dart';

class ComparisonIndicator extends StatelessWidget {
  final String title;
  final String currentValue;
  final String previousValue;
  final String unit;
  final IconData icon;
  final Color color;

  const ComparisonIndicator({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.icon,
    required this.color,
  });

  (double, String) _calculateDifference() {
    try {
      if (title.toLowerCase().contains('blood pressure')) {
        final current = _parseBloodPressure(currentValue);
        final previous = _parseBloodPressure(previousValue);
        if (current == null || previous == null) return (0.0, '0');
        
        final avgDiff = ((current.$1 - previous.$1) + (current.$2 - previous.$2)) / 2;
        return (avgDiff, avgDiff.toStringAsFixed(1));
      } else {
        // Handle potential non-numeric or invalid values
        final curr = double.tryParse(currentValue) ?? 0.0;
        final prev = double.tryParse(previousValue) ?? 0.0;
        final diff = curr - prev;
        return (diff, diff.toStringAsFixed(1));
      }
    } catch (e) {
      print('Error calculating difference: $e');
      return (0.0, '0');
    }
  }

  (double, double)? _parseBloodPressure(String value) {
    try {
      final parts = value.split('/');
      if (parts.length != 2) return null;
      
      final systolic = double.tryParse(parts[0].trim());
      final diastolic = double.tryParse(parts[1].trim());
      
      if (systolic == null || diastolic == null) return null;
      return (systolic, diastolic);
    } catch (e) {
      print('Error parsing blood pressure: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clean the values by removing any duplicate units
    String cleanCurrentValue = _cleanValueFromUnit(currentValue, unit);
    String cleanPreviousValue = _cleanValueFromUnit(previousValue, unit);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      cleanPreviousValue == 'N/A' 
                          ? 'N/A' 
                          : '$cleanPreviousValue $unit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      cleanCurrentValue == 'N/A' 
                          ? 'N/A' 
                          : '$cleanCurrentValue $unit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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

  String _cleanValueFromUnit(String value, String unit) {
    if (value == 'N/A') return value;
    
    // Map of unit variations to handle similar units written differently
    final unitVariations = {
      'gm/dL': ['gm/dl', 'g/dl', 'g/dL'],
      'fL': ['fl', 'FL'],
      // Add more variations as needed
    };
    
    // Remove the main unit and its variations
    String cleanValue = value;
    
    // Remove the unit if it appears at the end of the value
    cleanValue = cleanValue.replaceAll(RegExp(r'\s*' + unit + r'\s*$'), '');
    
    // Remove any variations of the unit
    unitVariations.forEach((mainUnit, variations) {
      if (unit.toLowerCase() == mainUnit.toLowerCase()) {
        for (var variation in variations) {
          cleanValue = cleanValue.replaceAll(RegExp(r'\s*' + variation + r'\s*'), '');
        }
      }
    });
    
    return cleanValue.trim();
  }
}
