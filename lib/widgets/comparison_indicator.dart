import 'package:flutter/material.dart';
import '../utils/test_definitions.dart';

class ComparisonIndicator extends StatelessWidget {
  final String title;
  final String currentValue;
  final String? previousValue;
  final String unit;
  final IconData icon;
  final Color color;
  final String? referenceRange;
  final String? fullName;
  final String? medicalAbbreviation;

  const ComparisonIndicator({
    super.key,
    required this.title,
    required this.currentValue,
    this.previousValue,
    required this.unit,
    required this.icon,
    required this.color,
    this.referenceRange,
    this.fullName,
    this.medicalAbbreviation,
  });

  String? _calculateDifference() {
    if (previousValue == null || previousValue == 'N/A' || currentValue == 'N/A') {
      return null;
    }

    try {
      // Special handling for Blood Pressure
      if (title.toLowerCase().contains('blood pressure') || 
          title.toLowerCase().contains('bp')) {
        final currentParts = _stripUnits(currentValue).split('/');
        final previousParts = _stripUnits(previousValue!).split('/');
        
        if (currentParts.length == 2 && previousParts.length == 2) {
          final currentSystolic = double.parse(currentParts[0]);
          final previousSystolic = double.parse(previousParts[0]);
          final difference = currentSystolic - previousSystolic;
          return difference.abs().toStringAsFixed(0);
        }
      }

      // Normal handling for other values
      final current = double.parse(_stripUnits(currentValue));
      final previous = double.parse(_stripUnits(previousValue!));
      final difference = current - previous;
      return difference.abs().toStringAsFixed(1);
    } catch (e) {
      return null;
    }
  }

  bool? _isIncrease() {
    if (previousValue == null || previousValue == 'N/A' || currentValue == 'N/A') {
      return null;
    }

    try {
      final current = double.parse(_stripUnits(currentValue));
      final previous = double.parse(_stripUnits(previousValue!));
      return current > previous;
    } catch (e) {
      return null;
    }
  }

  void _showReferenceRangeDialog(BuildContext context) {
    bool isWithinRange = _isWithinReferenceRange();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWithinRange ? Icons.check_circle : Icons.warning,
              color: isWithinRange ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Value:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$currentValue $unit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Normal Range:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              referenceRange ?? 'Not available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method to check if value is within reference range
  bool _isWithinReferenceRange() {
    if (referenceRange == null || currentValue == 'N/A') return true;
    
    try {
      // Extract numeric values and range bounds using regex
      final numericRegex = RegExp(r'([-+]?\d*\.?\d+)');
      final currentMatch = numericRegex.firstMatch(currentValue);
      
      // Extract range values - assuming format like "60-100" or "< 100" or "> 60"
      final rangeRegex = RegExp(r'([<>]?\s*\d+\.?\d*)\s*[-]?\s*([<>]?\s*\d+\.?\d*)?');
      final rangeMatch = rangeRegex.firstMatch(referenceRange!);
      
      if (currentMatch == null || rangeMatch == null) return true;
      
      final currentVal = double.parse(currentMatch.group(1)!);
      
      // Parse lower bound
      String? lowerStr = rangeMatch.group(1)?.replaceAll(RegExp(r'[<>\s]'), '');
      double? lowerBound = lowerStr != null ? double.parse(lowerStr) : null;
      
      // Parse upper bound
      String? upperStr = rangeMatch.group(2)?.replaceAll(RegExp(r'[<>\s]'), '');
      double? upperBound = upperStr != null ? double.parse(upperStr) : null;
      
      // Check if value is within range
      bool withinRange = true;
      if (lowerBound != null) withinRange = withinRange && currentVal >= lowerBound;
      if (upperBound != null) withinRange = withinRange && currentVal <= upperBound;
      
      return withinRange;
    } catch (e) {
      // If there's any error in parsing, return true to avoid showing warning
      return true;
    }
  }

  // Helper method to extract unit from value
  String _extractUnit(String value) {
    if (value == 'N/A') return '';
    
    // Special handling for Blood Pressure
    if (title.toLowerCase().contains('blood pressure') || 
        title.toLowerCase().contains('bp')) {
      final hasMmHg = value.toLowerCase().contains('mm') && 
                      value.toLowerCase().contains('hg');
      return hasMmHg ? 'mm Hg' : 'mm Hg';  // Default to mm Hg for BP
    }
    
    // Common units pattern with more specific matching
    final unitRegex = RegExp(r'[\d,.]+\s*(cells/cmm|[a-zA-Z/%]+/?[a-zA-Z]*|mm\s*Hg)');
    final match = unitRegex.firstMatch(value);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? '';
    }
    return '';
  }

  // Helper method to strip units from values
  String _stripUnits(String value) {
    if (value == 'N/A') return value;
    
    // Special handling for Blood Pressure
    if (title.toLowerCase().contains('blood pressure') || 
        title.toLowerCase().contains('bp')) {
      return value.split(' ')[0];  // Take only the BP numbers (e.g., "120/80")
    }
    
    // Updated regex to handle larger numbers with commas
    final numericRegex = RegExp(r'([\d,]+\.?\d*)');
    final match = numericRegex.firstMatch(value);
    if (match != null) {
      // Remove commas from the number
      return match.group(1)?.replaceAll(',', '') ?? value;
    }
    return value;
  }

  // Modify the trend analysis color logic
  Color _getTrendColor(bool isIncrease) {
    bool isPositiveChange = _isIncreasePositive() == isIncrease;
    
    if (isPositiveChange) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  // Update the trend analysis widget
  Widget _buildTrendAnalysis() {
    final difference = _calculateDifference();
    final isIncrease = _isIncrease();
    
    if (difference == null || isIncrease == null) return const SizedBox.shrink();

    final trendColor = _getTrendColor(isIncrease);
    final isPositive = _isIncreasePositive() == isIncrease;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              color: trendColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend Analysis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${isIncrease ? 'Increased' : 'Decreased'} by $difference $unit',
                      style: TextStyle(
                        fontSize: 16,
                        color: trendColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPositive ? 'Good' : 'Monitor',
                        style: TextStyle(
                          fontSize: 12,
                          color: trendColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to determine if an increase is good for this test
  bool _isIncreasePositive() {
    // Tests where an increase is generally concerning
    final increaseConcerning = [
      'Blood Pressure',
      'Glucose',
      'Blood Sugar',
      'Cholesterol',
      'Triglycerides',
      'SGPT',
      'SGOT',
      'Creatinine',
      'Urea',
      'BMI',
      'Weight',
      'HbA1C',
    ];

    // Tests where an increase is generally good
    final increasePositive = [
      'Hemoglobin',
      'SpO2',
      'Oxygen',
      'HDL',
      'Vitamin',
      'Calcium',
      'Protein',
      'Iron',
    ];

    // Check if title contains any of the keywords
    bool isConcerning = increaseConcerning.any(
      (keyword) => title.toLowerCase().contains(keyword.toLowerCase())
    );
    bool isPositive = increasePositive.any(
      (keyword) => title.toLowerCase().contains(keyword.toLowerCase())
    );

    // If not in either list, treat as neutral
    if (!isConcerning && !isPositive) {
      return true; // Default to positive if unknown
    }

    return isPositive;
  }

  void _showTestInfoDialog(BuildContext context) {
    final testInfo = TestDefinitions.getTestInfo(title);
    
    if (testInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What this test measures:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              testInfo,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Modify the unit display for BMI
    String displayUnit = unit;
    if (title == 'BMI') {
      displayUnit = 'kg/m²';  // Use the correct BMI unit with proper superscript
    } else {
      displayUnit = unit.isEmpty ? _extractUnit(currentValue) : unit;
    }
    
    // Strip units from values
    final cleanCurrentValue = _stripUnits(currentValue);
    final cleanPreviousValue = previousValue != null ? _stripUnits(previousValue!) : null;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Icon Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (displayUnit.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Unit: $displayUnit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (TestDefinitions.hasTestInfo(title))
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                    tooltip: 'Test Information',
                    onPressed: () => _showTestInfoDialog(context),
                  ),
                if (referenceRange != null)
                  IconButton(
                    icon: Icon(
                      Icons.straighten,
                      color: _isWithinReferenceRange() ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    tooltip: 'View Reference Range',
                    onPressed: () => _showReferenceRangeDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Values Grid
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              children: [
                // Current Value Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cleanCurrentValue,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (cleanPreviousValue != null) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final difference = _calculateDifference();
                            final isIncrease = _isIncrease();
                            
                            if (difference == null || isIncrease == null) {
                              return const SizedBox.shrink();
                            }

                            return Row(
                              children: [
                                Icon(
                                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: isIncrease ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  difference,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isIncrease ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Previous Value Box
                if (cleanPreviousValue != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            cleanPreviousValue,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
