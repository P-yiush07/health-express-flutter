import 'package:flutter/material.dart';
import '../screens/category_detail_screen.dart';
import '../services/report_preference_service.dart';

class CategoriesGrid extends StatefulWidget {
  const CategoriesGrid({super.key});

  @override
  State<CategoriesGrid> createState() => CategoriesGridState();
}

class CategoriesGridState extends State<CategoriesGrid> {
  Key _gridKey = UniqueKey();
  Map<String, dynamic> categoryData = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCategoryData();
  }

  Future<void> _loadSavedCategoryData() async {
    final savedData = await ReportPreferenceService.getCategoryData();
    if (savedData.isNotEmpty) {
      updateCategoryData(savedData);
    }
  }

  void refreshGrid() {
    if (mounted) {
      setState(() {
        _gridKey = UniqueKey();
      });
    }
  }

  void updateCategoryData(Map<String, dynamic> newData) {
    setState(() {
      categoryData = Map<String, dynamic>.from(newData);
    });
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    // Get the normalized category key and safely cast the data
    final normalizedTitle = title.toLowerCase().replaceAll(' ', '_');
    final categoryInfo = categoryData[normalizedTitle] as Map<String, dynamic>? ?? {};
    final tests = (categoryInfo['tests'] as Map<dynamic, dynamic>? ?? {})
        .cast<String, dynamic>();
    final summary = categoryInfo['summary'] as String? ?? '';
    
    // Count valid tests (not "not found" or null values)
    int testCount = 0;
    tests.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value['value'] != 'not found' && value['value'] != null) {
          testCount++;
        }
      }
    });

    // Process KPI data for navigation
    final kpiData = _processTestsToKPI(tests, title);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (testCount > 0) {  // Only navigate if there are valid tests
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    title: title,
                    icon: icon,
                    color: color,
                    kpiData: kpiData,
                    summary: summary,
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$testCount results',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategorySummary(String category) {
    if (category.isEmpty) {
      return 'Medical test results and measurements.';
    }

    switch (category.toLowerCase()) {
      case 'vitals':
        return 'Key vital signs including blood pressure, heart rate, and body measurements.';
      case 'glucose':
        return 'Blood sugar measurements that help monitor diabetes and metabolic health.';
      case 'lft':
        return 'Liver Function Tests evaluate the health of your liver by measuring various enzymes and proteins.';
      case 'vitamins':
        return 'Essential nutrients that your body needs for proper functioning.';
      case 'thyroid':
        return 'Hormones that regulate metabolism, energy, and growth.';
      case 'cbc':
        return 'Complete Blood Count provides information about your blood cells.';
      case 'lipid profiles':
        return 'Blood fat levels including cholesterol and triglycerides.';
      case 'kidney functions':
        return 'Tests that evaluate kidney function and electrolyte balance.';
      case 'other':
        return 'Additional medical tests and measurements.';
      default:
        return 'Medical test results and measurements.';
    }
  }

  List<Map<String, dynamic>> _processTestsToKPI(Map<String, dynamic> tests, String category) {
    final List<Map<String, dynamic>> kpiData = [];
    
    tests.forEach((testKey, testValue) {
      if (testValue is Map) {
        final testData = (testValue as Map<dynamic, dynamic>).cast<String, dynamic>();
        if (testData['value'] != 'not found' && testData['value'] != null) {
          kpiData.add({
            'title': testData['full_name'] ?? testKey,
            'value': testData['value'],
            'medical_abbreviation': testData['medical_abbreviation'],
            'category': category,
            'reference_range': testData['reference_range'],
          });
        }
      }
    });
    
    return kpiData;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          key: _gridKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.0,
          children: [
            _buildCategoryCard(
              context,
              'Vitals',
              Icons.favorite_rounded,
              const Color(0xFFFF5252),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Glucose',
              Icons.water_drop_rounded,
              const Color(0xFF448AFF),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'LFT',
              Icons.science_rounded,
              const Color(0xFFFFB74D),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Vitamins',
              Icons.brightness_7_rounded,
              const Color(0xFFE040FB),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Thyroid',
              Icons.psychology_rounded,
              const Color(0xFF64FFDA),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'CBC',
              Icons.bloodtype_rounded,
              const Color(0xFFFF4081),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Lipid Profiles',
              Icons.monitor_heart_rounded,
              const Color(0xFF69F0AE),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Kidney Functions',
              Icons.medical_information_rounded,
              const Color(0xFFFFD740),
              const Color(0xFF1A237E),
            ),
            _buildCategoryCard(
              context,
              'Other',
              Icons.more_horiz_rounded,
              const Color(0xFF90CAF9),
              const Color(0xFF1A237E),
            ),
          ],
        ),
      ],
    );
  }
}
