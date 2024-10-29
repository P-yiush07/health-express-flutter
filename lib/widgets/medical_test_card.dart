import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/medical_test_result.dart';

class MedicalTestCard extends StatelessWidget {
  final MedicalTestResult test;
  
  const MedicalTestCard({
    Key? key,
    required this.test,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (test.status.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProgressIndicator() {
    final percentage = test.normalRangeMax != null 
      ? (test.value / test.normalRangeMax!) 
      : null;

    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: percentage ?? 0.5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
            strokeWidth: 10,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${test.value}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                Text(
                  test.unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              test.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _buildProgressIndicator()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      test.interpretation,
                      style: TextStyle(
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (test.normalRangeMin != null && test.normalRangeMax != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Normal range: ${test.normalRangeMin} - ${test.normalRangeMax} ${test.unit}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

