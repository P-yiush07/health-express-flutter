import 'package:flutter/material.dart';
import '../widgets/comparison_indicator.dart';
import '../services/ai_service.dart';
import '../screens/chat_screen.dart';
import '../widgets/ai_floating_chat_button.dart';
import '../services/report_comparison_service.dart';
import '../services/reference_range_service.dart';
import 'dart:math';
import '../services/report_preference_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> kpiData;
  final String? summary;

  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.kpiData,
    this.summary,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool hasMultipleReports = false;
  Map<String, dynamic> previousValues = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Get the comparison report path
    final comparisonReportPath = await ReportPreferenceService.getComparisonReport();
    
    if (comparisonReportPath != null) {
      print('Comparison report selected: $comparisonReportPath');
      final prevValues = await ReportComparisonService.getPreviousValues(widget.kpiData);
      print('Previous values received: $prevValues');
      
      setState(() {
        hasMultipleReports = true;
        previousValues = prevValues;
      });
    } else {
      setState(() {
        hasMultipleReports = false;
        previousValues = {};
      });
    }
  }

  String _generateCategoryContent() {
    final buffer = StringBuffer();
    buffer.writeln('Category: ${widget.title}');
    buffer.writeln('Summary: ${widget.summary ?? 'No summary available'}');
    buffer.writeln('');
    buffer.writeln('Latest Measurements:');
    
    for (final kpi in widget.kpiData) {
      buffer.writeln('${kpi['title']}:');
      buffer.writeln('Current Value: ${kpi['value']} ${kpi['unit'] ?? ''}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  IconData _getIconForMetric(String metricName) {
    final metricIcons = {
      // Vital Signs
      'Blood Pressure': Icons.favorite,
      'Heart Rate': Icons.monitor_heart,
      'Temperature': Icons.thermostat,
      'Pulse': Icons.monitor_heart_outlined,
      'BMI': Icons.monitor_weight,
      'Weight': Icons.scale,
      'Height': Icons.height,
      'SpO2': Icons.air,
      'Oxygen': Icons.air_outlined,
      
      // Blood Tests
      'Glucose': Icons.water_drop,
      'Blood Sugar': Icons.water_drop,
      'Hemoglobin': Icons.bloodtype,
      'Cholesterol': Icons.medication_liquid,
      'Triglycerides': Icons.medication_liquid_outlined,
      'Creatinine': Icons.science,
      'Urea': Icons.science_outlined,
      
      // Electrolytes
      'Sodium': Icons.battery_full,
      'Potassium': Icons.battery_charging_full,
      'Chloride': Icons.electric_bolt,
      'Calcium': Icons.medication,
      
      // Liver Function
      'SGPT': Icons.medical_information,
      'SGOT': Icons.medical_information_outlined,
      'Bilirubin': Icons.colorize,
      'Albumin': Icons.science,
      
      // Urine Tests
      'Urine': Icons.water,
      'Protein': Icons.science,
      
      // Imaging
      'X-Ray': Icons.image,
      'MRI': Icons.medical_information,
      'CT Scan': Icons.medical_services,
      'Ultrasound': Icons.waves,
      
      // General Categories
      'Thyroid': Icons.personal_injury,
      'Kidney': Icons.medication_liquid,
      'Liver': Icons.medical_services,
      'Diabetes': Icons.water_drop,
      'Cardiac': Icons.monitor_heart,
      'Respiratory': Icons.air,
      'Bone': Icons.accessibility_new,
    };

    // First try exact matches
    if (metricIcons.containsKey(metricName)) {
      return metricIcons[metricName]!;
    }

    // Then try partial matches
    for (var entry in metricIcons.entries) {
      if (metricName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // If no specific icon is found, try to match category-based keywords
    final categoryKeywords = {
      'test': Icons.science,
      'count': Icons.numbers,
      'rate': Icons.speed,
      'index': Icons.analytics,
      'level': Icons.show_chart,
      'score': Icons.score,
      'ratio': Icons.percent,
      'blood': Icons.bloodtype,
      'pressure': Icons.speed,
      'volume': Icons.water_drop,
      'enzyme': Icons.science,
      'hormone': Icons.medication,
      'vitamin': Icons.medication_liquid,
      'mineral': Icons.diamond,
      'protein': Icons.science,
      'function': Icons.functions,
    };

    for (var entry in categoryKeywords.entries) {
      if (metricName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Default fallback icon
    return Icons.analytics;
  }

  String _extractUnit(String value) {
    final unitRegex = RegExp(r'\s*([a-zA-Z/%]+/?[a-zA-Z]*|mm\s*Hg)$');
    final match = unitRegex.firstMatch(value);
    return match?.group(1) ?? '';
  }

  List<Map<String, dynamic>> _processTestData(List<Map<String, dynamic>> kpiData) {
    return kpiData.expand((kpi) {
      if (kpi['value'] is Map<String, dynamic>) {
        final Map<String, dynamic> nestedValues = kpi['value'];
        return nestedValues.entries.map((entry) {
          final currentValue = entry.value['value']?.toString() ?? 'N/A';
          String? previousVal;
          
          if (hasMultipleReports && previousValues[kpi['title']] != null) {
            previousVal = previousValues[kpi['title']][entry.key]?['value']?.toString();
          }
          
          return <String, dynamic>{
            'title': entry.key,
            'value': currentValue,
            'unit': entry.value['unit'] ?? _extractUnit(currentValue),
            'previousValue': previousVal,
            'full_name': entry.value['full_name'],
            'medical_abbreviation': entry.value['medical_abbreviation'],
            'referenceRange': entry.value['reference_range'],
          };
        });
      } else {
        return [<String, dynamic>{
          ...kpi,
          'previousValue': previousValues[kpi['title']]?['value']?.toString(),
          'referenceRange': kpi['reference_range'],
        }];
      }
    }).where((kpi) => 
      kpi['value'] != null && 
      kpi['value'].toString().toLowerCase() != 'n/a'
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final validKpis = _processTestData(widget.kpiData);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
      ),
      floatingActionButton: validKpis.isNotEmpty
          ? AIFloatingChatButton(
              categoryTitle: widget.title,
              categoryContent: _generateCategoryContent(),
              kpiData: validKpis,
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.summary ?? 'No summary available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (validKpis.isNotEmpty) ...[
                const Text(
                  'Latest Measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...validKpis.map((kpi) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ComparisonIndicator(
                    title: kpi['title'],
                    currentValue: kpi['value'].toString(),
                    previousValue: kpi['previousValue'],
                    unit: kpi['unit']?.toString() ?? '',
                    icon: _getIconForMetric(kpi['title']),
                    color: widget.color,
                    referenceRange: kpi['referenceRange'],
                  ),
                )).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
