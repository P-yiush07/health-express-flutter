import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_preference_service.dart';

class ReportHistoryDialog extends StatefulWidget {
  final VoidCallback onHistoryDeleted;

  const ReportHistoryDialog({
    Key? key,
    required this.onHistoryDeleted,
  }) : super(key: key);

  @override
  State<ReportHistoryDialog> createState() => _ReportHistoryDialogState();
}

class _ReportHistoryDialogState extends State<ReportHistoryDialog> {
  Map<String, dynamic>? activeReportData;
  String? activeReportPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveReportData();
  }

  Future<void> _loadActiveReportData() async {
    try {
      // Get the active report path
      final activePath = await ReportPreferenceService.getActiveReport();
      if (activePath == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get the data for the active report
      final allReportData = await ReportPreferenceService.getReportDataMap();
      final activeData = allReportData[activePath];

      setState(() {
        activeReportPath = activePath;
        activeReportData = activeData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading active report data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteReportData() async {
    if (activeReportPath != null) {
      await ReportPreferenceService.deleteReportData(activeReportPath!);
      widget.onHistoryDeleted();
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Active Report History',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      actions: [
        if (activeReportData != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: _deleteReportData,
            child: const Text('Delete History'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (activeReportPath == null) {
      return const Center(
        child: Text(
          'No active report selected',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (activeReportData == null) {
      return const Center(
        child: Text(
          'No history available for the active report',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final reportName = activeReportPath!.split('/').last;
    final timestamp = DateTime.now(); // Default to current time if no timestamp

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report: $reportName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(timestamp)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (activeReportData!['kpis'] != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'KPI Values:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ...((activeReportData!['kpis'] as List).map((kpi) {
              if (kpi is Map<String, dynamic>) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(kpi['title']?.toString() ?? 'Unknown'),
                    subtitle: Text('Value: ${kpi['value']?.toString() ?? 'N/A'} ${kpi['unit']?.toString() ?? ''}'),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList()),
          ],
        ],
      ),
    );
  }
} 