import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/chat_history.dart';
import '../widgets/kpi_selection_dialog.dart';
import '../services/kpi_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/report_block.dart';
import 'dart:convert';
import '../models/medical_test_result.dart';
import '../widgets/medical_test_card.dart';

class ChatScreenConstants {
  static const Color primaryColor = Color(0xFF5c258d);
  static const double sectionSpacing = 16.0;
  static const double itemSpacing = 8.0;
  static const double labelWidth = 120.0;
  static const double borderRadius = 12.0;
}

class ChatScreen extends StatefulWidget {
  final dynamic selectedReport;
  final String reportName;
  final String pdfContent;

  const ChatScreen({
    Key? key,
    required this.selectedReport,
    required this.reportName,
    required this.pdfContent,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<ChatMessage> _messages;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAIGeneratingResponse = false;
  final String _initialGreeting = "Hello! I'm your AI assistant. How can I help you with your medical report?";
  bool _hasUserSentMessage = false;
  late Stream<List<ChatMessage>> _chatStream;

  @override
  void initState() {
    super.initState();
    _messages = AIService.getChatHistory(widget.selectedReport.id);
    _hasUserSentMessage = _messages.isNotEmpty;
    _isAIGeneratingResponse = AIService.isAIGeneratingResponse(widget.selectedReport.id);
    _chatStream = _createChatStream();
  }

  Stream<List<ChatMessage>> _createChatStream() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      final messages = AIService.getChatHistory(widget.selectedReport.id);
      _isAIGeneratingResponse = AIService.isAIGeneratingResponse(widget.selectedReport.id);
      return messages;
    }).distinct((previous, current) => 
      listEquals(previous, current) &&
      _isAIGeneratingResponse == AIService.isAIGeneratingResponse(widget.selectedReport.id)
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isAIGeneratingResponse = true;
      if (!_hasUserSentMessage) {
        _hasUserSentMessage = true;
      }
    });

    // Add the user's message to the chat history
    await AIService.addUserMessage(widget.selectedReport.id, widget.reportName, text);
    _refreshMessages();

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Generate AI response
    await AIService.generateResponseInBackground(text, widget.pdfContent, widget.selectedReport.id, widget.reportName);
    
    setState(() {
      _isAIGeneratingResponse = false;
    });
    _refreshMessages();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text('Are you sure you want to clear the entire chat history?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () async {
                await AIService.clearChatHistory(widget.selectedReport.id);
                setState(() {
                  _messages = [ChatMessage(
                    text: "Hello! I'm your AI assistant. How can I help you with your medical report?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  )];
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showKPISelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return KPISelectionDialog(
          pdfContent: widget.pdfContent,
          onKPIsSelected: (selectedKPIs) {
            KPIService.addKPIsToDashboard(selectedKPIs);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('KPIs added to dashboard')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AIService.saveChatHistory(widget.selectedReport.id, widget.reportName, _messages);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5c258d),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.health_and_safety, color: Color(0xFF5c258d)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Date: ${widget.selectedReport.date.toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_chart, color: Colors.white),
              onPressed: _showKPISelectionDialog,
              tooltip: 'Add KPIs to Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                // TODO: Show info dialog or navigate to info page
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'clear') {
                  _clearChat();
                } else {
                  // TODO: Handle other menu item selections
                  print('Selected: $value');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Text('Clear chat history'),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                const PopupMenuItem<String>(
                  value: 'feedback',
                  child: Text('Send feedback'),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF0F0F0),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatStream,
                  initialData: _messages,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    _isAIGeneratingResponse = AIService.isAIGeneratingResponse(widget.selectedReport.id);
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      itemBuilder: (_, int index) {
                        if (messages.isEmpty && index == 0) {
                          return _buildChatMessage(ChatMessage(
                            text: _initialGreeting,
                            isUser: false,
                            timestamp: DateTime.now(),
                          ));
                        }
                        if (_isAIGeneratingResponse && index == 0) {
                          return _buildTypingIndicator();
                        }
                        return _buildChatMessage(messages[index - (_isAIGeneratingResponse ? 1 : 0)]);
                      },
                      itemCount: messages.isEmpty ? 1 : messages.length + (_isAIGeneratingResponse ? 1 : 0),
                    );
                  },
                ),
              ),
              const Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF5c258d),
            foregroundColor: Colors.white,
            child: Icon(Icons.health_and_safety),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "AI is thinking",
                    style: TextStyle(
                      color: Color(0xFF5c258d),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5c258d)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF5c258d),
              foregroundColor: Colors.white,
              child: Icon(Icons.health_and_safety),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF5c258d).withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormattedText(message.text),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF5c258d),
              foregroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    if (text.contains('🏥 Medical Analysis Report')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: text.split('\n').map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 8);
          
          // Main Report Title
          if (line.contains('🏥 Medical Analysis Report')) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF5c258d).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5c258d).withOpacity(0.2)),
              ),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF5c258d),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          
          // Section Headers (Overview, Test Results Analysis, etc.)
          if (line.contains('📋 Overview:') || 
              line.contains('🔬 Test Results Analysis:') ||
              line.contains('⚠️ Notable Findings:') ||
              line.contains('💡 Recommendations:')) {
            return Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5c258d).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF5c258d),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          
          // Test Names
          if (line.trim().startsWith('•')) {
            return Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF5c258d),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          
          // Test Details (Measured Value, Reference Range, etc.)
          if (line.trim().startsWith('-')) {
            final parts = line.substring(1).split(':');
            if (parts.length == 2) {
              return Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      child: Text(
                        parts[0].trim(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parts[1].trim(),
                        style: TextStyle(
                          color: _getStatusColor(parts[1].trim()),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          
          // Regular text
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              line,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      );
    }
    
    return Text(
      text,
      style: const TextStyle(color: Colors.black87),
    );
  }

  // Add this helper method to color-code status values
  Color _getStatusColor(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('normal')) return Colors.green;
    if (lowerText.contains('high')) return Colors.red;
    if (lowerText.contains('low')) return Colors.orange;
    if (lowerText.contains('critical')) return Colors.red[700]!;
    return Colors.black87;
  }

  Widget _buildCircularIndicator({
    required double value,
    required String unit,
    required String status,
    required double min,
    required double max,
  }) {
    final percentage = (value - min) / (max - min);
    final color = status.toLowerCase() == 'normal' 
        ? Colors.blue 
        : status.toLowerCase() == 'high' 
            ? Colors.red 
            : Colors.orange;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 10,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBlock(String content) {
    final lines = content.trim().split('\n');
    final title = lines[0];
    final value = lines[1];
    final description = lines.sublist(2).join('\n');

    return ReportBlock(
      title: title,
      value: value,
      description: description,
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _isAIGeneratingResponse ? null : _handleSubmitted,
              decoration: const InputDecoration(
                hintText: "Send a message",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isAIGeneratingResponse ? null : () => _handleSubmitted(_textController.text),
            color: const Color(0xFF5c258d),
          ),
        ],
      ),
    );
  }

  // Add this method to refresh the messages when the screen is focused
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMessages();
    });
  }

  void _refreshMessages() {
    setState(() {
      _messages = AIService.getChatHistory(widget.selectedReport.id);
      _isAIGeneratingResponse = AIService.isAIGeneratingResponse(widget.selectedReport.id);
    });
  }
}
