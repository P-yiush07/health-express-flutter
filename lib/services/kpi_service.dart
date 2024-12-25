import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/category_mappings.dart';

class KPIService {
  static const String _kpiKey = 'dashboard_kpis';
  static const String _latestKPIsKey = 'latest_kpis';

  static Future<void> addKPIsToDashboard(List<Map<String, dynamic>> kpis) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKPIs = await getDashboardKPIs();
    currentKPIs.addAll(kpis);
    await prefs.setString(_kpiKey, jsonEncode(currentKPIs));
  }

  static Future<List<Map<String, dynamic>>> getDashboardKPIs() async {
    final prefs = await SharedPreferences.getInstance();
    final kpisJson = prefs.getString(_kpiKey);
    if (kpisJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(kpisJson));
    }
    return [];
  }

  static Future<void> removeKPIFromDashboard(String kpiTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKPIs = await getDashboardKPIs();
    currentKPIs.removeWhere((kpi) => kpi['title'] == kpiTitle);
    await prefs.setString(_kpiKey, jsonEncode(currentKPIs));
  }

  static Future<void> saveLatestKPIs(Map<String, dynamic> apiData) async {
    try {
      final List<Map<String, dynamic>> processedKPIs = [];
      
      apiData.forEach((category, data) {
        if (data is Map<String, dynamic> && data['tests'] is Map<String, dynamic>) {
          final tests = data['tests'] as Map<String, dynamic>;
          
          tests.forEach((testName, testValue) {
            if (testValue is Map<String, dynamic>) {
              // Handle nested objects like Serum Electrolytes
              testValue.forEach((subTestName, subTestValue) {
                processedKPIs.add({
                  'title': testName + ' - ' + subTestName,
                  'value': subTestValue.toString(),
                  'category': category,
                  'unit': _extractUnit(subTestValue.toString()),
                });
              });
            } else {
              processedKPIs.add({
                'title': testName,
                'value': testValue.toString(),
                'category': category,
                'unit': _extractUnit(testValue.toString()),
              });
            }
          });
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_latestKPIsKey, jsonEncode(processedKPIs));
      print('Saved ${processedKPIs.length} KPIs to storage');
    } catch (e) {
      print('Error saving KPIs: $e');
    }
  }

  static String _extractUnit(String value) {
    // Common units in medical tests
    final units = [
      'mg/dl', 'g/dl', 'mmol/L', 'µIU/mL', 'ng/mL', 'µg/dL',
      'mm/hr', 'cells/cmm', '%', 'fL', 'pg', 'U/L', 'million/cmm',
      'Lakh/cmm', 'mm of Hg', 'kg/m2', 'cms', 'kg'
    ];

    for (var unit in units) {
      if (value.toLowerCase().contains(unit.toLowerCase())) {
        return unit;
      }
    }
    return '';
  }

  static Future<List<Map<String, dynamic>>> getLatestKPIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kpisJson = prefs.getString(_latestKPIsKey);
      if (kpisJson != null) {
        final List<dynamic> decoded = jsonDecode(kpisJson);
        final List<Map<String, dynamic>> kpis = decoded.map((item) => 
          Map<String, dynamic>.from(item as Map<String, dynamic>)
        ).toList();
        
        print('Retrieved KPIs from storage: $kpis'); // Debug log
        return kpis;
      }
    } catch (e) {
      print('Error getting KPIs: $e');
    }
    return [];
  }

  static Future<void> clearLatestKPIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latestKPIsKey);
      print('Latest KPIs cleared');
    } catch (e) {
      print('Error clearing KPIs: $e');
    }
  }

  // Helper method to normalize titles
  static String _normalizeTitle(String title) {
    // Map common variations of titles to standard names
    final titleMap = {
      'heart rate': 'Heart Rate',
      'heartrate': 'Heart Rate',
      'pulse': 'Heart Rate',
      'blood pressure': 'Blood Pressure',
      'bp': 'Blood Pressure',
      'blood sugar': 'Blood Sugar',
      'glucose': 'Blood Sugar',
      'random blood sugar': 'Blood Sugar',
      'r blood sugar': 'Blood Sugar',
      'bmi': 'BMI',
      'body mass index': 'BMI',
    };
    
    final normalizedTitle = title.toLowerCase().trim();
    return titleMap[normalizedTitle] ?? title;
  }

  static Future<List<Map<String, dynamic>>> getCategoryKPIs(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kpisJson = prefs.getString(_latestKPIsKey);
      if (kpisJson != null) {
        final List<dynamic> allKPIs = jsonDecode(kpisJson);
        return allKPIs
            .where((kpi) => kpi['category'] == category)
            .map((kpi) => Map<String, dynamic>.from(kpi))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting category KPIs: $e');
      return [];
    }
  }
}
