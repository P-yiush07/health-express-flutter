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

  static Future<void> saveLatestKPIs(List<Map<String, dynamic>> kpis) async {
    try {
      if (kpis.isEmpty) {
        await clearLatestKPIs();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final normalizedKpis = kpis.map((kpi) {
        final category = CategoryMappings.getCategoryForMetric(kpi['title'].toString());
        return {
          'title': kpi['title']?.toString() ?? '',
          'value': kpi['value']?.toString() ?? 'N/A',
          'previousValue': kpi['previousValue']?.toString() ?? 'N/A',
          'unit': kpi['unit']?.toString() ?? '',
          'category': category ?? 'Other',
        };
      }).toList();
      
      await prefs.setString(_latestKPIsKey, jsonEncode(normalizedKpis));
    } catch (e) {
      print('Error saving KPIs: $e');
    }
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
}
