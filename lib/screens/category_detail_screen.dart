import 'package:flutter/material.dart';
import '../widgets/comparison_indicator.dart';
import '../services/ai_service.dart';
import '../screens/chat_screen.dart';
import '../widgets/ai_floating_chat_button.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> kpiData;

  const CategoryDetailScreen({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.kpiData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5c258d),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      floatingActionButton: kpiData.isNotEmpty
          ? AIFloatingChatButton(
              categoryTitle: title,
              categoryContent: _generateCategoryContent(),
              kpiData: kpiData,
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
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, String>>(
                future: AIService.getStoredCategorySummaries(),
                builder: (context, snapshot) {
                  String summary = 'Loading...';
                  if (snapshot.hasData) {
                    summary = snapshot.data![title] ?? 'No summary available';
                  } else if (snapshot.hasError) {
                    summary = 'Error loading summary';
                  }
                  return Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (kpiData.isNotEmpty) ...[
                const Text(
                  'Latest Measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...kpiData.map((kpi) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ComparisonIndicator(
                    title: kpi['title'],
                    currentValue: kpi['value'],
                    previousValue: kpi['previousValue'],
                    unit: kpi['unit'],
                    icon: _getIconForMetric(kpi['title']),
                    color: color,
                  ),
                )).toList(),
              ] else
                const Center(
                  child: Text(
                    'No measurements available for this category',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForMetric(String metricName) {
    // Add metric-specific icons here
    final metricIcons = {
      'Blood Pressure': Icons.favorite,
      'Heart Rate': Icons.monitor_heart,
      'Temperature': Icons.thermostat,
      // Add more mappings as needed
    };

    for (var entry in metricIcons.entries) {
      if (metricName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return Icons.analytics; // Default icon
  }

  String _getCategorySummary(String category) {
    switch (category.toLowerCase()) {
      case 'vitals':
        return 'Essential measurements of your body\'s basic functions, including heart rate, blood pressure, and temperature. These indicators provide a quick snapshot of your overall health status.';
      case 'glucose':
        return 'Blood sugar measurements that help monitor diabetes and metabolic health. Regular tracking ensures optimal glucose control and helps prevent complications.';
      case 'lft':
        return 'Liver Function Tests evaluate the health of your liver by measuring various enzymes and proteins. These tests help detect liver damage or disease.';
      case 'vitamins':
        return 'Essential nutrients that your body needs for proper functioning. Regular monitoring ensures optimal levels and helps prevent deficiencies.';
      case 'thyroid':
        return 'Hormones that regulate metabolism, energy, and growth. These tests help monitor thyroid function and detect any imbalances.';
      case 'cbc':
        return 'Complete Blood Count provides information about your blood cells, helping detect various conditions like anemia, infection, and blood disorders.';
      default:
        return 'Detailed health metrics and measurements to help you track and understand your medical condition.';
    }
  }

  String _generateCategoryContent() {
    final buffer = StringBuffer();
    buffer.writeln('Category: $title');
    buffer.writeln('');
    
    for (final kpi in kpiData) {
      buffer.writeln('${kpi['title']}:');
      buffer.writeln('Current Value: ${kpi['value']} ${kpi['unit']}');
      if (kpi['previousValue'] != null && kpi['previousValue'] != 'N/A') {
        buffer.writeln('Previous Value: ${kpi['previousValue']} ${kpi['unit']}');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}
