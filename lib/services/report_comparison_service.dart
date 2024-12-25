import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../services/report_preference_service.dart';

class ReportComparisonService {
  static Future<int> getAvailableReportsCount() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final pdfPaths = manifestMap.keys
          .where((String key) => key.contains('assets/') && key.endsWith('.pdf'))
          .toList();

      print('Number of available reports: ${pdfPaths.length}');
      
      return pdfPaths.length;
    } catch (e) {
      print('Error getting available reports count: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getPreviousValues(List<Map<String, dynamic>> currentKpis) async {
    try {
      final allReportsData = await ReportPreferenceService.getReportDataMap();
      print('All reports data: ${allReportsData.length} reports found');
      
      final sortedReports = allReportsData.entries.toList()
        ..sort((a, b) {
          final dateA = DateTime.parse(a.value['timestamp'] ?? '');
          final dateB = DateTime.parse(b.value['timestamp'] ?? '');
          return dateB.compareTo(dateA);
        });

      if (sortedReports.length < 2) {
        return {};
      }

      final previousReport = sortedReports[1].value;
      
      // Get both KPIs and category data
      final previousKpis = List<Map<String, dynamic>>.from(previousReport['kpis'] ?? []);
      final previousCategories = Map<String, dynamic>.from(previousReport['categories'] ?? {});
      
      print('Previous report KPIs: ${previousKpis.length} KPIs found');
      print('Previous report Categories found: ${previousCategories.keys.length}');
      
      final previousValues = <String, dynamic>{};
      
      for (final currentKpi in currentKpis) {
        final currentTitle = currentKpi['title'] as String;
        print('Looking for previous value for: $currentTitle');
        
        // First check in KPIs
        var previousKpi = previousKpis.firstWhere(
          (kpi) => _isSameTest(kpi['title'] as String, currentTitle),
          orElse: () => {'value': null},
        );

        // If not found in KPIs, check in categories
        if (previousKpi['value'] == null) {
          for (final category in previousCategories.entries) {
            final categoryTests = category.value['tests'] as Map<String, dynamic>?;
            if (categoryTests != null) {
              for (final test in categoryTests.entries) {
                if (_isSameTest(test.key, currentTitle)) {
                  previousKpi = {'value': test.value};
                  break;
                }
              }
            }
          }
        }

        if (currentKpi['value'] is Map<String, dynamic>) {
          final nestedValues = <String, dynamic>{};
          final currentNestedValues = currentKpi['value'] as Map<String, dynamic>;
          final previousNestedValues = previousKpi['value'] is Map<String, dynamic> 
              ? previousKpi['value'] as Map<String, dynamic>
              : <String, dynamic>{};

          for (final key in currentNestedValues.keys) {
            nestedValues[key] = previousNestedValues[key] ?? 'N/A';
          }
          previousValues[currentTitle] = nestedValues;
        } else {
          previousValues[currentTitle] = previousKpi['value'] ?? 'N/A';
        }
        
        print('Stored previous value for $currentTitle: ${previousValues[currentTitle]}');
      }

      return previousValues;
    } catch (e) {
      print('Error getting previous values: $e');
      return {};
    }
  }

  // Helper method to compare test names
  static bool _isSameTest(String test1, String test2) {
    final normalize = (String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[()-]'), '')  // Remove parentheses and hyphens
        .replaceAll(RegExp(r'\s+'), ' ')   // Normalize whitespace
        .trim();

    // Map common abbreviations
    final abbreviations = {
      'fbs': ['fasting blood sugar', 'plasma glucose fasting'],
      'ppbs': ['post prandial blood sugar', 'plasma glucose post prandial'],
      'rbs': ['random blood sugar'],
    };

    final test1Norm = normalize(test1);
    final test2Norm = normalize(test2);

    // Direct match
    if (test1Norm == test2Norm) return true;

    // Check abbreviations
    for (final entry in abbreviations.entries) {
      final abbr = entry.key;
      final variations = entry.value;
      
      final isTest1Match = test1Norm.contains(abbr) || 
          variations.any((v) => test1Norm.contains(v));
      final isTest2Match = test2Norm.contains(abbr) || 
          variations.any((v) => test2Norm.contains(v));
      
      if (isTest1Match && isTest2Match) return true;
    }

    return false;
  }
}
