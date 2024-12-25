import 'package:flutter/material.dart';
import '../models/chat_history.dart';
import '../services/chat_storage_service.dart';

class CategoryChatScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryContent;
  final List<Map<String, dynamic>> kpiData;

  const CategoryChatScreen({
    Key? key,
    required this.categoryTitle,
    required this.categoryContent,
    required this.kpiData,
  }) : super(key: key);

  @override
  _CategoryChatScreenState createState() => _CategoryChatScreenState();
}

class _CategoryChatScreenState extends State<CategoryChatScreen> {
  final List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _storedKPIData = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAIGeneratingResponse = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final categoryData = await ChatStorageService.getCategoryData(widget.categoryTitle);
    setState(() {
      _messages.addAll(categoryData['messages'] as List<ChatMessage>);
      _storedKPIData = categoryData['kpiData'] as List<Map<String, dynamic>>;
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _isAIGeneratingResponse = true;
    });

    // Save messages and KPI data
    await ChatStorageService.saveCategoryChat(
      widget.categoryTitle,
      _messages,
      widget.kpiData,  // Save current KPI data
    );

    // Scroll to top
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Simulate AI response after a short delay
    await Future.delayed(const Duration(seconds: 1));

    // Add mock AI response
    final aiMessage = ChatMessage(
      text: "This is a demo response for the ${widget.categoryTitle} category. In a real implementation, this would be an AI-generated response.",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, aiMessage);
      _isAIGeneratingResponse = false;
    });

    // Save the updated chat with AI response
    await ChatStorageService.saveCategoryChat(widget.categoryTitle, _messages, widget.kpiData);
  }

  // Add a method to clear chat history
  Future<void> _clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: Text('Are you sure you want to clear the chat history for ${widget.categoryTitle}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Clear'),
            onPressed: () async {
              await ChatStorageService.clearCategoryData(widget.categoryTitle);
              setState(() {
                _messages.clear();
              });
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        backgroundColor: const Color(0xFF5c258d),
        elevation: 2,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 20,
              child: Icon(
                Icons.medical_information,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _clearChat,
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              // Show category info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    widget.categoryTitle,
                    style: const TextStyle(
                      color: Color(0xFF5c258d),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'This is the AI chat assistant for ${widget.categoryTitle}. '
                    'You can ask questions about your medical data in this category.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFF5c258d),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF5c258d).withOpacity(0.08),
                  const Color(0xFF5c258d).withOpacity(0.03),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF5c258d).withOpacity(0.1),
                ),
                bottom: BorderSide(
                  color: const Color(0xFF5c258d).withOpacity(0.1),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5c258d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,  // Changed to a more suggestive icon
                    size: 16,
                    color: const Color(0xFF5c258d),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask questions about your ${widget.categoryTitle.toLowerCase()} data',
                  style: TextStyle(
                    color: const Color(0xFF5c258d).withOpacity(0.8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length + (_isAIGeneratingResponse ? 1 : 0) + 1, // +1 for KPI card
              itemBuilder: (context, index) {
                if (index == _messages.length + (_isAIGeneratingResponse ? 1 : 0)) {
                  return _buildKPISummary();
                }
                if (_isAIGeneratingResponse && index == 0) {
                  return _buildTypingIndicator();
                }
                return _buildChatMessage(_messages[index - (_isAIGeneratingResponse ? 1 : 0)]);
              },
            ),
          ),
          const Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF5c258d),
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
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
                  "LabAI is thinking",
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5c258d)),
                  ),
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF5c258d),
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF5c258d)  // User message background
                    : Colors.white,            // AI message background
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF5c258d),
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _isAIGeneratingResponse ? null : _handleSubmitted,
              decoration: InputDecoration(
                hintText: "Ask about ${widget.categoryTitle.toLowerCase()}...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: _isAIGeneratingResponse 
                  ? Colors.grey[400]
                  : const Color(0xFF5c258d),
            ),
            onPressed: _isAIGeneratingResponse 
                ? null 
                : () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF5c258d).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Category KPI Values:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5c258d),
              ),
            ),
          ),
          ...widget.kpiData.map((kpi) {
            String valueStr = kpi['value'].toString();
            String? previousValueStr = kpi['previousValue']?.toString();
            
            String unit = kpi['unit']?.toString() ?? '';
            if (unit.isEmpty) {
              unit = _extractUnit(valueStr);
            }
            
            String cleanValue = valueStr.replaceAll(unit, '').trim();
            String? cleanPreviousValue = previousValueStr?.replaceAll(unit, '').trim();

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF5c258d).withOpacity(0.05),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kpi['title'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5c258d).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5c258d),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Current: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            cleanValue,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5c258d),
                            ),
                          ),
                        ],
                      ),
                      if (cleanPreviousValue != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Prev: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              cleanPreviousValue,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5c258d),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _extractUnit(String value) {
    // Updated regex to better capture units
    final unitRegex = RegExp(r'[0-9.]+\s*([a-zA-Z/%]+/?[a-zA-Z]*|mm\s*Hg)$');
    final match = unitRegex.firstMatch(value);
    return match?.group(1)?.trim() ?? '';
  }
}
