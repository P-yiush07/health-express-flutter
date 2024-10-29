import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_history.dart';

class ChatStorageService {
  static const String _categoryChatsKey = 'category_chats';
  static const String _categoryKPIKey = 'category_kpi_data';

  // Save messages and KPI data for a specific category
  static Future<void> saveCategoryChat(
    String categoryTitle, 
    List<ChatMessage> messages,
    List<Map<String, dynamic>> kpiData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save chat messages
      Map<String, List<Map<String, dynamic>>> allChats = {};
      final String? existingChatsJson = prefs.getString(_categoryChatsKey);
      if (existingChatsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(existingChatsJson);
        decoded.forEach((key, value) {
          if (value is List) {
            allChats[key] = List<Map<String, dynamic>>.from(value);
          }
        });
      }

      allChats[categoryTitle] = messages.map((msg) => {
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
      }).toList();

      await prefs.setString(_categoryChatsKey, jsonEncode(allChats));

      // Save KPI data
      Map<String, List<Map<String, dynamic>>> allKPIData = {};
      final String? existingKPIJson = prefs.getString(_categoryKPIKey);
      if (existingKPIJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(existingKPIJson);
        decoded.forEach((key, value) {
          if (value is List) {
            allKPIData[key] = List<Map<String, dynamic>>.from(value);
          }
        });
      }

      allKPIData[categoryTitle] = kpiData;
      await prefs.setString(_categoryKPIKey, jsonEncode(allKPIData));

    } catch (e) {
      print('Error saving chat and KPI data: $e');
    }
  }

  // Get messages and KPI data for a specific category
  static Future<Map<String, dynamic>> getCategoryData(String categoryTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get chat messages
      final String? chatsJson = prefs.getString(_categoryChatsKey);
      List<ChatMessage> messages = [];
      if (chatsJson != null) {
        final Map<String, dynamic> chatsMap = jsonDecode(chatsJson);
        final dynamic categoryMessages = chatsMap[categoryTitle];
        
        if (categoryMessages is List) {
          messages = List<Map<String, dynamic>>.from(categoryMessages)
              .map((msg) => ChatMessage(
                    text: msg['text'] as String,
                    isUser: msg['isUser'] as bool,
                    timestamp: DateTime.parse(msg['timestamp'] as String),
                  ))
              .toList();
        }
      }

      // Get KPI data
      final String? kpiJson = prefs.getString(_categoryKPIKey);
      List<Map<String, dynamic>> kpiData = [];
      if (kpiJson != null) {
        final Map<String, dynamic> kpiMap = jsonDecode(kpiJson);
        final dynamic categoryKPIs = kpiMap[categoryTitle];
        
        if (categoryKPIs is List) {
          kpiData = List<Map<String, dynamic>>.from(categoryKPIs);
        }
      }

      return {
        'messages': messages,
        'kpiData': kpiData,
      };
    } catch (e) {
      print('Error getting category data: $e');
      return {
        'messages': <ChatMessage>[],
        'kpiData': <Map<String, dynamic>>[],
      };
    }
  }

  // Clear category data (both chat and KPI)
  static Future<void> clearCategoryData(String categoryTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear chat messages
      final String? chatsJson = prefs.getString(_categoryChatsKey);
      if (chatsJson != null) {
        final Map<String, dynamic> chatsMap = jsonDecode(chatsJson);
        chatsMap.remove(categoryTitle);
        await prefs.setString(_categoryChatsKey, jsonEncode(chatsMap));
      }

      // Clear KPI data
      final String? kpiJson = prefs.getString(_categoryKPIKey);
      if (kpiJson != null) {
        final Map<String, dynamic> kpiMap = jsonDecode(kpiJson);
        kpiMap.remove(categoryTitle);
        await prefs.setString(_categoryKPIKey, jsonEncode(kpiMap));
      }
    } catch (e) {
      print('Error clearing category data: $e');
    }
  }
}
