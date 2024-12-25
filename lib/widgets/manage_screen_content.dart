import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../utils/date_utils.dart';
import '../services/report_preference_service.dart';

class ManageScreenContent extends StatefulWidget {
  final Function(String)? onReportChanged;

  const ManageScreenContent({
    Key? key,
    this.onReportChanged,
  }) : super(key: key);

  @override
  State<ManageScreenContent> createState() => _ManageScreenContentState();
}

class _ManageScreenContentState extends State<ManageScreenContent> {
  List<Map<String, dynamic>> pdfFiles = [];
  String? activeReport;
  String? comparisonReport;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
    _loadActiveReport();
    _loadComparisonReport();
  }

  Future<void> _loadActiveReport() async {
    final savedReport = await ReportPreferenceService.getActiveReport();
    if (savedReport != null) {
      setState(() {
        activeReport = savedReport;
      });
      widget.onReportChanged?.call(savedReport);
    }
  }

  Future<void> _setActiveReport(String? value) async {
    if (value != null) {
      await ReportPreferenceService.setActiveReport(value);
      // Clear comparison report when switching active report
      await ReportPreferenceService.setComparisonReport(null);
      setState(() {
        activeReport = value;
        comparisonReport = null;  // Clear comparison report in state
      });
      
      widget.onReportChanged?.call(value);
    }
  }

  Future<void> _loadPdfFiles() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    
    final pdfPaths = manifestMap.keys
        .where((String key) => key.contains('assets/') && key.endsWith('.pdf'))
        .toList();

    setState(() {
      pdfFiles = pdfPaths.map((path) {
        final name = path.split('/').last;
        return {
          'path': path,
          'name': name,
          'date': ReportDateUtils.generateReportDate(name),
        };
      }).toList();

      // Sort by date in descending order
      pdfFiles.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );

      // Format dates after sorting
      pdfFiles = pdfFiles.map((file) {
        return {
          ...file,
          'date': ReportDateUtils.formatReportDate(file['date'] as DateTime),
        };
      }).toList();
    });


  }

  Future<void> _loadComparisonReport() async {
    final savedReport = await ReportPreferenceService.getComparisonReport();
    if (savedReport != null) {
      setState(() {
        comparisonReport = savedReport;
      });
    }
  }

  void _setComparisonReport(String? value) async {
    await ReportPreferenceService.setComparisonReport(value);
    setState(() {
      comparisonReport = value;
    });
    
    // Trigger refresh of KPIs
    if (widget.onReportChanged != null) {
      final activeReport = await ReportPreferenceService.getActiveReport();
      if (activeReport != null) {
        widget.onReportChanged!(activeReport);
      }
    }
  }

  void _clearComparisonReport() async {
    await ReportPreferenceService.setComparisonReport(null);
    setState(() {
      comparisonReport = null;
    });
    
    // Trigger refresh of KPIs
    if (widget.onReportChanged != null) {
      final activeReport = await ReportPreferenceService.getActiveReport();
      if (activeReport != null) {
        widget.onReportChanged!(activeReport);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: PageStorageBucket(),
      child: ListView(
        key: const PageStorageKey<String>('manageScreenListView'),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Select Active Report',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...pdfFiles.map((file) => Card(
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.white),
              title: Text(
                file['name'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                file['date'] as String,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Radio<String>(
                value: file['path'] as String,
                groupValue: activeReport,
                onChanged: _setActiveReport,
                fillColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Colors.white
                      : Colors.white70,
                ),
              ),
            ),
          )).toList(),

          // Show divider and "Compare With" title when active report is selected
          if (activeReport != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white24, thickness: 1),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compare With',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (comparisonReport != null)
                    TextButton.icon(
                      onPressed: _clearComparisonReport,
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      label: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),

            // Only show comparison options when there's an active report
            ...pdfFiles.where((file) => file['path'] != activeReport).map((file) => Card(
              color: Colors.white.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  file['name'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['date'] as String,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (activeReport != null && file['path'] != activeReport)
                      Text(
                        _getDateDifference(file),
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Radio<String>(
                  value: file['path'] as String,
                  groupValue: comparisonReport,
                  onChanged: _setComparisonReport,
                  fillColor: MaterialStateProperty.resolveWith(
                    (states) => states.contains(MaterialState.selected)
                        ? Colors.blue[300]
                        : Colors.white70,
                  ),
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  String _getDateDifference(Map<String, dynamic> file) {
    final activeFile = pdfFiles.firstWhere(
      (f) => f['path'] == activeReport,
      orElse: () => {'name': ''},
    );
    
    // Get dates directly from filenames
    final activeDate = ReportDateUtils.generateReportDate(activeFile['name'] as String);
    final compareDate = ReportDateUtils.generateReportDate(file['name'] as String);

    final difference = activeDate.difference(compareDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days older';
    } else if (difference.inDays < 0) {
      return '${-difference.inDays} days newer';
    } else {
      return 'Same day';
    }
  }
}
