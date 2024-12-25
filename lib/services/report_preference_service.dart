import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReportPreferenceService {
  static const String _activeReportKey = 'active_report';
  static const String _comparisonReportKey = 'comparison_report';
  static const String _reportDataKey = 'report_data';
  static const String _categoryDataKey = 'category_data';

  static Future<void> setActiveReport(String reportPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeReportKey, reportPath);
  }

  static Future<String?> getActiveReport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeReportKey);
  }

  static Future<void> saveReportData(String reportPath, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final reportData = await getReportDataMap();
    reportData[reportPath] = {
      ...data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_reportDataKey, jsonEncode(reportData));
  }

  static Future<Map<String, dynamic>> getReportDataMap() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_reportDataKey);
    return dataString != null ? Map<String, dynamic>.from(jsonDecode(dataString)) : {};
  }

  static Future<void> deleteReportData(String reportPath) async {
    final prefs = await SharedPreferences.getInstance();
    final reportData = await getReportDataMap();
    reportData.remove(reportPath);
    await prefs.setString(_reportDataKey, jsonEncode(reportData));
  }

  static Future<void> saveCategoryData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryDataKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_categoryDataKey);
    return dataString != null ? Map<String, dynamic>.from(jsonDecode(dataString)) : {};
  }

  static Future<void> clearCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_categoryDataKey);
  }

  static Future<void> setComparisonReport(String? reportPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (reportPath != null) {
      await prefs.setString(_comparisonReportKey, reportPath);
    } else {
      await prefs.remove(_comparisonReportKey);
    }
  }

  static Future<String?> getComparisonReport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_comparisonReportKey);
  }

  static String? getLatestReport(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return null;
    
    // Reports should already be sorted by date in descending order
    final latestReport = reports.first;
    return latestReport['name'] as String;
  }
}
