import 'package:flutter/material.dart';

class PreviousReportsList extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final int maxReports;
  final VoidCallback onShowMore;
  final Function(String) openPdf;

  const PreviousReportsList({
    super.key,
    required this.reports,
    this.maxReports = 4,
    required this.onShowMore,
    required this.openPdf,
  });

  @override
  Widget build(BuildContext context) {
    final displayedReports = reports.take(maxReports).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Previous Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Increased from 20
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: onShowMore,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16, // Increased from 16
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: displayedReports.length,
              itemBuilder: (context, index) {
                final report = displayedReports[index];
                final title = report['name'] as String;
                final date = report['date'] as String;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => openPdf(report['path'] as String),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.description, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16, // Increased from 14
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.white70, 
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
