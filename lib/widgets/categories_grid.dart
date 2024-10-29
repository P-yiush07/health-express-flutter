import 'package:flutter/material.dart';
import '../screens/category_detail_screen.dart';
import '../utils/category_mappings.dart';
import '../services/kpi_service.dart';

class CategoriesGrid extends StatefulWidget {
  const CategoriesGrid({super.key});

  @override
  State<CategoriesGrid> createState() => CategoriesGridState();
}

class CategoriesGridState extends State<CategoriesGrid> {
  // Add a key to force rebuild
  Key _gridKey = UniqueKey();

  void refreshGrid() {
    setState(() {
      _gridKey = UniqueKey();
    });
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
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color, Color bgColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // Get the actual KPI data for this category
      future: _getCategoryKPIData(title),
      builder: (context, snapshot) {
        // Get the count of actual KPIs
        final kpiCount = snapshot.hasData ? snapshot.data!.length : 0;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(0.8),
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
              onTap: () async {
                if (snapshot.hasData) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreen(
                        title: title,
                        icon: icon,
                        color: color,
                        kpiData: snapshot.data!,
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
                      '$kpiCount results',
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
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getCategoryKPIData(String category) async {
    final allKPIs = await KPIService.getLatestKPIs();
    
    return allKPIs.where((kpi) {
      final metricName = kpi['title'].toString();
      final metricCategory = CategoryMappings.getCategoryForMetric(metricName);
      return metricCategory == category;
    }).toList();
  }
}
