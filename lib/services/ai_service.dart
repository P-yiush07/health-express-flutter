import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';
import '../models/chat_history.dart';
import 'package:flutter/material.dart';
import '../widgets/stored_values_dialog.dart';
import '../services/kpi_service.dart';

class AIService {
  static const String apiKey = 'sk-proj-Thr49483muTIk8kXanc9T3BlbkFJ49VRuw3yT77JcB0TlALk';
  static List<ChatHistory> chatHistories = [];
  static Map<String, bool> isGeneratingResponse = {};
  static List<dynamic> storedValues = [];
  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get refreshStream => _refreshController.stream;

  static Future<void> loadChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historiesJson = prefs.getString('chat_histories');
    if (historiesJson != null) {
      final List<dynamic> decoded = jsonDecode(historiesJson);
      chatHistories = decoded.map((item) => ChatHistory.fromJson(item)).toList();
    }
  }

  static Future<void> saveChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final String historiesJson = jsonEncode(chatHistories.map((h) => h.toJson()).toList());
    await prefs.setString('chat_histories', historiesJson);
  }

  static List<ChatMessage> getChatHistory(String reportId) {
    final history = chatHistories.firstWhere(
      (history) => history.reportId == reportId,
      orElse: () => ChatHistory(reportId: reportId, reportName: '', messages: [], lastUpdated: DateTime.now()),
    );
    return history.messages;
  }

  static Future<void> saveChatHistory(String reportId, String reportName, List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      return; // Don't save empty chat histories
    }
    
    final existingHistoryIndex = chatHistories.indexWhere((history) => history.reportId == reportId);
    if (existingHistoryIndex != -1) {
      chatHistories[existingHistoryIndex] = ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: messages,
        lastUpdated: DateTime.now(),
      );
    } else {
      chatHistories.add(ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: messages,
        lastUpdated: DateTime.now(),
      ));
    }
    chatHistories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    await saveChatHistories();
  }

  static Future<String> generateResponse(String prompt, String pdfContent) async {
    OpenAI.apiKey = apiKey;

    try {
      // Check if this is the first message (requesting full report)
      final isInitialAnalysis = prompt.toLowerCase().contains('report') || 
                              prompt.toLowerCase().contains('analyze') ||
                              prompt.toLowerCase().contains('summary');

      final promptTemplate = isInitialAnalysis ? """
        You are a healthcare assistant analyzing medical reports. Provide a comprehensive analysis using this format:

        🏥 Medical Analysis Report

        📋 Overview:
        [Provide a brief, clear summary of the key findings]

        🔬 Test Results Analysis:
        [For each test result found in the report:]
        • [Test Name]
          - Measured Value: [value with units]
          - Reference Range: [normal range]
          - Status: [Normal/High/Low/Critical]
          - Clinical Significance: [Brief medical interpretation]
          - Recommendation: [If applicable]

        ⚠️ Notable Findings:
        [List any abnormal or significant results that require attention]

        💡 Recommendations:
        [Provide relevant health recommendations based on the results]
      """ : """
        You are a healthcare assistant. Using the medical report provided, answer the user's question directly and conversationally. 
        Focus only on addressing their specific question while maintaining medical accuracy.
        If the question requires medical advice, remind them to consult with their healthcare provider.
      """;

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """$promptTemplate

                Medical Report Content: $pdfContent
                
                Question: $prompt"""
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final responseContent = chatCompletion.choices.first.message.content;
      if (responseContent != null && responseContent.isNotEmpty) {
        return responseContent.first.text ?? 'No response generated.';
      } else {
        return 'No response generated.';
      }
    } catch (e) {
      print('Error generating AI response: $e');
      return 'Sorry, I encountered an error while processing your request.';
    }
  }

  static Future<void> clearChatHistory(String reportId) async {
    await deleteChatHistory(reportId);
  }

  static Future<void> deleteChatHistory(String reportId) async {
    chatHistories.removeWhere((history) => history.reportId == reportId);
    await saveChatHistories();
  }

  static Future<void> generateResponseInBackground(String prompt, String pdfContent, String reportId, String reportName) async {
    // Set the generating state to true
    isGeneratingResponse[reportId] = true;

    // Generate AI response in the background
    String aiResponse = await _generateResponse(prompt, pdfContent);
    
    // Add AI response to chat history
    await _updateChatHistoryWithAIResponse(reportId, reportName, aiResponse);
    
    // Set the generating state to false
    isGeneratingResponse[reportId] = false;
  }

  static bool isAIGeneratingResponse(String reportId) {
    return isGeneratingResponse[reportId] ?? false;
  }

  static Future<String> _generateResponse(String prompt, String pdfContent) async {
    OpenAI.apiKey = apiKey;

    try {
      // Check if this is the first message (requesting full report)
      final isInitialAnalysis = prompt.toLowerCase().contains('report') || 
                              prompt.toLowerCase().contains('analyze') ||
                              prompt.toLowerCase().contains('summary');

      final promptTemplate = isInitialAnalysis ? """
        You are a healthcare assistant analyzing medical reports. Provide a comprehensive analysis using this format:

        🏥 Medical Analysis Report

        📋 Overview:
        [Provide a brief, clear summary of the key findings]

        🔬 Test Results Analysis:
        [For each test result found in the report:]
        • [Test Name]
          - Measured Value: [value with units]
          - Reference Range: [normal range]
          - Status: [Normal/High/Low/Critical]
          - Clinical Significance: [Brief medical interpretation]
          - Recommendation: [If applicable]

        ⚠️ Notable Findings:
        [List any abnormal or significant results that require attention]

        💡 Recommendations:
        [Provide relevant health recommendations based on the results]
      """ : """
        You are a healthcare assistant. Using the medical report provided, answer the user's question directly and conversationally. 
        Focus only on addressing their specific question while maintaining medical accuracy.
        If the question requires medical advice, remind them to consult with their healthcare provider.
      """;

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """$promptTemplate

                Medical Report Content: $pdfContent
                
                Question: $prompt"""
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final responseContent = chatCompletion.choices.first.message.content;
      return responseContent != null && responseContent.isNotEmpty
          ? responseContent.first.text ?? 'No response generated.'
          : 'No response generated.';
    } catch (e) {
      print('Error generating AI response: $e');
      return 'Sorry, I encountered an error while processing your request.';
    }
  }

  static Future<void> _updateChatHistoryWithUserMessage(String reportId, String reportName, String userPrompt) async {
    final existingHistoryIndex = chatHistories.indexWhere((history) => history.reportId == reportId);
    if (existingHistoryIndex != -1) {
      final updatedMessages = List<ChatMessage>.from(chatHistories[existingHistoryIndex].messages);
      updatedMessages.insert(0, ChatMessage(text: userPrompt, isUser: true, timestamp: DateTime.now()));
      
      chatHistories[existingHistoryIndex] = ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: updatedMessages,
        lastUpdated: DateTime.now(),
      );
    } else {
      chatHistories.add(ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: [ChatMessage(text: userPrompt, isUser: true, timestamp: DateTime.now())],
        lastUpdated: DateTime.now(),
      ));
    }
    chatHistories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    await saveChatHistories();
  }

  static Future<void> _updateChatHistoryWithAIResponse(String reportId, String reportName, String aiResponse) async {
    final existingHistoryIndex = chatHistories.indexWhere((history) => history.reportId == reportId);
    if (existingHistoryIndex != -1) {
      final updatedMessages = List<ChatMessage>.from(chatHistories[existingHistoryIndex].messages);
      updatedMessages.insert(0, ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()));
      
      chatHistories[existingHistoryIndex] = ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: updatedMessages,
        lastUpdated: DateTime.now(),
      );
    } else {
      chatHistories.add(ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: [ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now())],
        lastUpdated: DateTime.now(),
      ));
    }
    await saveChatHistories();
  }

  static Future<void> addUserMessage(String reportId, String reportName, String message) async {
    final existingHistoryIndex = chatHistories.indexWhere((history) => history.reportId == reportId);
    if (existingHistoryIndex != -1) {
      final updatedMessages = List<ChatMessage>.from(chatHistories[existingHistoryIndex].messages);
      updatedMessages.insert(0, ChatMessage(text: message, isUser: true, timestamp: DateTime.now()));
      
      chatHistories[existingHistoryIndex] = ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: updatedMessages,
        lastUpdated: DateTime.now(),
      );
    } else {
      chatHistories.add(ChatHistory(
        reportId: reportId,
        reportName: reportName,
        messages: [ChatMessage(text: message, isUser: true, timestamp: DateTime.now())],
        lastUpdated: DateTime.now(),
      ));
    }
    await saveChatHistories();
  }

  static Future<void> storeGeneratedValues(List<Map<String, dynamic>> values, {String? reportContent}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().toIso8601String();
      
      // Normalize the values before storing
      final normalizedValues = values.map((value) {
        return {
          'title': value['title']?.toString() ?? '',
          'value': value['value']?.toString() ?? 'N/A',
          'previousValue': value['previousValue']?.toString() ?? 'N/A',
          'unit': value['unit']?.toString() ?? '',
          'timestamp': currentTime,
        };
      }).toList();
      
      final newEntry = {
        'timestamp': currentTime,
        'values': normalizedValues,
        'type': 'metrics',
        if (reportContent != null) 'report_content': reportContent,
      };
      
      if (!_isDuplicateEntry(storedValues, newEntry)) {
        storedValues.add(newEntry);
        if (storedValues.length > 10) {
          storedValues = storedValues.sublist(storedValues.length - 10);
        }
        await prefs.setString('generated_values', jsonEncode(storedValues));
        
        // Generate new summaries if report content is available
        if (reportContent != null) {
          await generateCategorySummaries(reportContent);
        }
        
        // Notify listeners to refresh
        _refreshController.add(null);
      }
    } catch (e) {
      print('Error storing generated values: $e');
    }
  }

  // Helper method to compare two lists of values
  static bool _areValuesEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['title']?.toString() != list2[i]['title']?.toString() ||
          list1[i]['value']?.toString() != list2[i]['value']?.toString() ||
          list1[i]['unit']?.toString() != list2[i]['unit']?.toString()) {
        return false;
      }
    }
    
    return true;
  }

  static Future<List<Map<String, dynamic>>> getStoredValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValuesJson = prefs.getString('generated_values') ?? '[]';
      final List<dynamic> decoded = jsonDecode(storedValuesJson);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      print('Error getting stored values: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> generateMedicalTerms(String pdfContent) async {
    try {
      OpenAI.apiKey = apiKey;
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """
                Given the following medical report content, please extract a list of important medical terms and their associated values. Focus on terms related to vital signs, lab results, and key health metrics.

                Medical report content:
                $pdfContent

                Please provide a list of 10-15 important medical terms and their values in the following format:
                Term: Value (Unit)

                For example:
                Blood Pressure: 120/80 (mmHg)
                Heart Rate: 72 (bpm)
                Cholesterol: 180 (mg/dL)
                """
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      if (chatCompletion.choices.isNotEmpty) {
        final content = chatCompletion.choices.first.message.content;
        if (content != null && content.isNotEmpty && content.first.type == 'text') {
          final text = content.first.text;
          final lines = text?.trim().split('\n') ?? [];
          final generatedValues = lines.map((line) {
            final parts = line.split(':');
            if (parts.length == 2) {
              final term = parts[0].trim();
              final valueWithUnit = parts[1].trim();
              final valueUnitParts = valueWithUnit.split(' ');
              final value = valueUnitParts[0];
              final unit = valueUnitParts.length > 1 ? valueUnitParts.sublist(1).join(' ').replaceAll(RegExp(r'[()]'), '') : '';
              return {'title': term, 'value': value, 'unit': unit};
            }
            return null;
          }).whereType<Map<String, dynamic>>().toList();

          // Store the generated values
          await storeGeneratedValues(generatedValues);
          
          return generatedValues;
        }
      }
      return [];
    } catch (e) {
      print('Error generating medical terms: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> compareRecentReports() async {
    if (chatHistories.length < 2) {
      return {'error': 'Not enough reports to compare.'};
    }

    final recentReports = chatHistories.take(2).toList();
    final report1Content = recentReports[0].messages.map((m) => m.text).join('\n');
    final report2Content = recentReports[1].messages.map((m) => m.text).join('\n');
    
    // Get the latest report content early
    final latestReportContent = recentReports[0].messages.map((m) => m.text).join('\n');

    try {
      OpenAI.apiKey = apiKey;
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """
                Compare the following two medical reports and extract the exact numerical differences in health metrics.
                For each metric, show the exact values from both reports in this format:
                [Metric Name]: [Exact Value from Report 1] -> [Exact Value from Report 2] ([Unit])

                Important:
                - Always show numerical values, not descriptive terms like "high" or "low"
                - If a value is missing, show "Not given"
                - Include units for each measurement
                - Format should be exactly: Metric: Value1 -> Value2 (Unit)

                Example format:
                Hemoglobin: 15.2 -> 11.6 (gm/dL)
                Blood Pressure: 125/85 -> 130/85 (mmHg)
                BMI: 26.6 -> 25.8
                
                Report 1:
                $report1Content

                Report 2:
                $report2Content

                Extract and compare all available numerical metrics following the exact format shown above.
                """
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final responseContent = chatCompletion.choices.first.message.content;
      if (responseContent != null && responseContent.isNotEmpty) {
        final comparisonText = responseContent.first.text ?? '';
        
        // Parse the comparison text into structured data
        final lines = comparisonText.trim().split('\n');
        final comparisonValues = lines.where((line) => line.trim().isNotEmpty).map((line) {
          final match = RegExp(r'(.*?):\s*(.*?)\s*->\s*(.*?)(?:\s*\((.*?)\))?$').firstMatch(line);
          if (match != null) {
            final title = match.group(1)?.trim() ?? '';
            final value1 = match.group(2)?.trim() ?? 'N/A';
            final value2 = match.group(3)?.trim() ?? 'N/A';
            final unit = match.group(4)?.trim() ?? '';

            return {
              'title': title,
              'value': value2 != 'Not given' ? value2 : value1,
              'previousValue': value1 != 'Not given' ? value1 : 'N/A',
              'unit': unit,
            };
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList();

        if (comparisonValues.isNotEmpty) {
          // Store comparison values in history with both current and previous values
          await storeGeneratedValues(comparisonValues, reportContent: latestReportContent);
          
          print('Generating summaries from latest report content: ${latestReportContent.substring(0, min(100, latestReportContent.length))}...');
          await generateCategorySummaries(latestReportContent);
        }

        return {
          'comparison': comparisonText,
          'structured_data': comparisonValues,
        };
      } else {
        return {'error': 'No differences found.'};
      }
    } catch (e) {
      print('Error comparing reports: $e');
      return {'error': 'Error comparing reports.'};
    }
  }

  static Future<Map<String, String>> generateCategorySummaries(String latestReportContent) async {
    try {
      print('Generating category summaries for content length: ${latestReportContent.length}');
      OpenAI.apiKey = apiKey;
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """
                Analyze the following medical report and generate summaries for each category of tests.
                Only generate a summary for categories that have relevant test results present in the report.
                If a category has no relevant tests, respond with "No data available".

                Important:
                - DO NOT include any patient names or personal identifiers in the summaries
                - Focus only on the medical values and their interpretations
                - Use neutral language like "The blood pressure is..." instead of "Patient's blood pressure..."

                Categories:
                1. Vitals (blood pressure, heart rate, temperature, etc.)
                2. Glucose (blood sugar, HbA1c, etc.)
                3. LFT (liver function tests)
                4. Vitamins (D, B12, etc.)
                5. Thyroid (TSH, T3, T4, etc.)
                6. CBC (complete blood count)

                Medical Report Content:
                $latestReportContent

                Format the response as:
                Category: Summary of findings
                """
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      if (chatCompletion.choices.isNotEmpty && 
          chatCompletion.choices.first.message.content != null && 
          chatCompletion.choices.first.message.content!.isNotEmpty) {
        final summaryText = chatCompletion.choices.first.message.content!.first.text ?? '';
        print('Received AI response for summaries: $summaryText');
        
        final summaries = <String, String>{};
        final categories = ['Vitals', 'Glucose', 'LFT', 'Vitamins', 'Thyroid', 'CBC'];
        
        // Parse the summaries
        final lines = summaryText.split('\n');
        for (final category in categories) {
          String summary = 'No data available';
          
          for (final line in lines) {
            // Match both "Category:" and "Number. Category:"
            if (line.contains('$category:')) {
              // Extract everything after the colon
              final colonIndex = line.indexOf(':');
              if (colonIndex != -1) {
                summary = line.substring(colonIndex + 1).trim();
                break;
              }
            }
          }
          
          summaries[category] = summary;
        }

        print('Parsed summaries before saving: $summaries');

        // Store summaries in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('category_summaries', jsonEncode(summaries));
        
        print('Successfully saved summaries to SharedPreferences');
        return summaries;
      }
      print('No valid response received from AI for summaries');
      return {};
    } catch (e) {
      print('Error generating category summaries: $e');
      return {};
    }
  }

  static Future<void> showStoredValues(BuildContext context) async {
    final storedValues = await getStoredValues();
    
    if (context.mounted) {
      if (storedValues.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No History'),
              content: const Text('No historical values are available yet.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StoredValuesDialog(storedValues: storedValues);
          },
        );
      }
    }
  }

  static Future<void> debugPrintStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValuesJson = prefs.getString('generated_values');
    print('Current stored values: $storedValuesJson');
  }

  static Future<void> deleteStoredValue(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValuesJson = prefs.getString('generated_values') ?? '[]';
      List<dynamic> storedValues = jsonDecode(storedValuesJson);
      
      // Remove the value at the specified index
      if (index >= 0 && index < storedValues.length) {
        storedValues.removeAt(index);
        
        // Save the updated list back to storage
        await prefs.setString('generated_values', jsonEncode(storedValues));
        
        // Notify listeners to refresh UI
        _refreshController.add(null);
        
        print('Value deleted successfully');
      }
    } catch (e) {
      print('Error deleting stored value: $e');
    }
  }

  static Future<void> deleteAllStoredValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('generated_values');
      await prefs.remove('category_summaries');
      await KPIService.clearLatestKPIs();
      
      // Notify listeners to refresh UI
      _refreshController.add(null);
      
      print('All values and summaries deleted successfully');
    } catch (e) {
      print('Error deleting stored values: $e');
    }
  }

  static bool _isDuplicateEntry(List<dynamic> storedValues, Map<String, dynamic> newEntry) {
    if (storedValues.isEmpty) return false;
    
    // Get the last entry
    final lastEntry = storedValues.last as Map<String, dynamic>;
    
    // Compare timestamps (if they're within 1 minute, consider potential duplicate)
    final lastTimestamp = DateTime.parse(lastEntry['timestamp']?.toString() ?? '');
    final newTimestamp = DateTime.parse(newEntry['timestamp']?.toString() ?? '');
    
    try {
      final timeDifference = newTimestamp.difference(lastTimestamp).inMinutes;
      
      if (timeDifference > 1) return false;
      
      // Compare values
      final lastValues = List<Map<String, dynamic>>.from(lastEntry['values'] ?? []);
      final newValues = List<Map<String, dynamic>>.from(newEntry['values'] ?? []);
      
      return _areValuesEqual(lastValues, newValues);
    } catch (e) {
      print('Error comparing entries: $e');
      return false;
    }
  }

  static Future<void> initializeStoredValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValuesJson = prefs.getString('generated_values');
      if (storedValuesJson != null) {
        storedValues = List<dynamic>.from(jsonDecode(storedValuesJson));
        print('Initialized stored values: $storedValues'); // Debug log
      } else {
        storedValues = [];
        print('No stored values found, initialized empty list');
      }
    } catch (e) {
      print('Error initializing stored values: $e');
      storedValues = [];
    }
  }

  static Future<Map<String, String>> getStoredCategorySummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJson = prefs.getString('category_summaries');
      if (summariesJson != null) {
        return Map<String, String>.from(jsonDecode(summariesJson));
      }
      return {};
    } catch (e) {
      print('Error getting stored category summaries: $e');
      return {};
    }
  }

  static void dispose() {
    _refreshController.close();
  }
}
