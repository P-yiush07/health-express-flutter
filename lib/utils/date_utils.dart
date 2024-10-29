import 'package:intl/intl.dart';

class ReportDateUtils {
  static DateTime generateReportDate(String reportName) {
    // Use the hash code of the report name to generate a consistent date
    final hash = reportName.hashCode.abs();
    final startDate = DateTime(2024, 1, 1);
    final days = hash % 365; // Ensures date stays within 2024
    return startDate.add(Duration(days: days));
  }

  static String formatReportDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
