import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart'; // Add this import
import '../models/report.dart';
import '../models/chat_history.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import 'chat_screen.dart';
import '../utils/date_utils.dart';

class ReportSelectionScreen extends StatefulWidget {
  const ReportSelectionScreen({super.key});

  @override
  _ReportSelectionScreenState createState() => _ReportSelectionScreenState();
}

class _ReportSelectionScreenState extends State<ReportSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Report> reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPdfFiles();
  }

  void _handleTabSelection() {
    if (_tabController.index == 1) {
      // Chat History tab
      setState(() {
        // This will trigger a rebuild of the chat history list
      });
    }
  }

  Future<void> _loadPdfFiles() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    
    final pdfPaths = manifestMap.keys
        .where((String key) => key.contains('assets/') && key.endsWith('.pdf'))
        .toList();

    setState(() {
      reports = pdfPaths.asMap().entries.map((entry) {
        final path = entry.value;
        final name = path.split('/').last.replaceAll('.pdf', '');
        return Report(
          id: entry.key.toString(),
          name: name,
          date: _generate2024Date(name),
          filePath: path,
        );
      }).toList();
    });
  }

  DateTime _generate2024Date(String reportName) {
    return ReportDateUtils.generateReportDate(reportName);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Medical Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5c258d),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Chat History'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList(),
          _buildChatHistoryList(),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final pdfContent = await PDFService.extractTextFromPDF(reports[index].filePath);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      selectedReport: reports[index],
                      reportName: reports[index].name,
                      pdfContent: pdfContent,
                    ),
                  ),
                ).then((_) {
                  // This will be called when returning from ChatScreen
                  setState(() {
                    // Trigger a rebuild of the widget
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'report_icon_${reports[index].id}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5c258d),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            reports[index].name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reports[index].name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5c258d),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${reports[index].date.toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF5c258d)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatHistoryList() {
    return ListView.builder(
      itemCount: AIService.chatHistories.length,
      itemBuilder: (context, index) {
        final history = AIService.chatHistories[index];
        return Dismissible(
          key: Key(history.reportId),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              AIService.chatHistories.removeAt(index);
            });
            AIService.saveChatHistories();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${history.reportName} chat history deleted')),
            );
          },
          child: ListTile(
            title: Text(history.reportName),
            subtitle: Text(
              history.messages.isNotEmpty ? history.messages.first.text : 'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              DateFormat('MMM d, yyyy').format(history.lastUpdated),
              style: TextStyle(color: Colors.grey[600]),
            ),
            onTap: () async {
              final report = reports.firstWhere((r) => r.id == history.reportId);
              final pdfContent = await PDFService.extractTextFromPDF(report.filePath);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    selectedReport: report,
                    reportName: report.name,
                    pdfContent: pdfContent,
                  ),
                ),
              ).then((_) {
                setState(() {});
              });
            },
          ),
        );
      },
    );
  }
}
