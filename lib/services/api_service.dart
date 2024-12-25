import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'report_preference_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'reference_range_service.dart';
import 'test_mapping_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<String?> getActiveReportPath() async {
    return await ReportPreferenceService.getActiveReport();
  }

  static Future<Map<String, dynamic>> fetchMedicalTests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medical-tests'));
      print('Medical Tests API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // New normalization with predefined categories
        final newNormalizedData = await TestMappingService.normalizeTestData(data);
        
        // // Log both results for comparison
        // print('\nComparison of normalizations:');
        // print('New normalization: ${json.encode(newNormalizedData)}');
        
        // Print each category separately
        print('\nNew normalization by category:');
        newNormalizedData.forEach((category, data) {
          print('\n$category:');
          print(json.encode(data));
        });
        
        return newNormalizedData; // Return the new normalization
      } else {
        throw Exception('Failed to fetch medical tests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching medical tests: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzePdfReport(String assetPath) async {
    try {
      // Create a temporary file from the asset
      final tempFile = await _createTempFileFromAsset(assetPath);
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze-pdf'));
      
      try {
        request.files.add(await http.MultipartFile.fromPath('file', tempFile.path));
      } catch (e) {
        throw Exception('Error reading PDF file: $e');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Analyze PDF API Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing PDF: $e');
      throw Exception('Failed to process PDF: $e');
    }
  }

  // Helper method to create a temporary file from an asset
  static Future<File> _createTempFileFromAsset(String assetPath) async {
    try {
      // Read asset file
      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
      
      // Write to temporary file
      await tempFile.writeAsBytes(bytes);
      
      return tempFile;
    } catch (e) {
      throw Exception('Failed to create temporary file from asset: $e');
    }
  }
}
