import 'dart:convert';
import '../data/test_definitions.dart';
import '../services/reference_range_service.dart';

class TestMappingService {

  // Initialize normalized data structure with "not found" values for all categories
  static Map<String, dynamic> initializeNormalizedStructure() {
    final normalizedData = <String, dynamic>{};
    
    // Initialize all possible categories, including those that might come from API
    final allCategories = [
      ...TestDefinitions.predefinedTests.keys,
      'Vitals',
      'Glucose',
      'LFT',
      'CBC',
      'Kidney Functions',
      'Vitamins',
      'Thyroid',
      'Lipid Profiles',
      'Other'
    ].toSet(); // Using Set to remove duplicates
    
    // Initialize structure for all categories
    for (var category in allCategories) {
      String normalizedCategory = _normalizeCategoryKey(category);
      normalizedData[normalizedCategory] = {
        "summary": "",
        "tests": {}
      };
      
      // Add predefined tests if they exist for this category
      if (TestDefinitions.predefinedTests.containsKey(normalizedCategory)) {
        final tests = TestDefinitions.predefinedTests[normalizedCategory]!;
        normalizedData[normalizedCategory]["tests"] = Map.fromEntries(
          tests.entries.map(
            (test) => MapEntry(test.key, {
              "value": "not found",
              "full_name": test.value["full_name"],
              "medical_abbreviation": test.value["medical_abbreviation"]
            })
          )
        );
      }
    }
    
    return normalizedData;
  }

  static String _normalizeCategoryKey(String category) {
    // Convert category names to consistent keys
    final mapping = {
      'Vitals': 'vitals',
      'Glucose': 'glucose',
      'LFT': 'lft',
      'CBC': 'cbc',
      'Kidney Functions': 'kidney_functions',
      'Vitamins': 'vitamins',
      'Thyroid': 'thyroid',
      'Lipid Profiles': 'lipid_profiles',
      'Other': 'other'
    };
    
    return mapping[category] ?? category.toLowerCase().replaceAll(' ', '_');
  }

  // Improved text normalization
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove content within parentheses
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ') // Remove special characters except spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  // Find matching predefined test in any category with improved matching
  static Map<String, String>? findMatchingPredefinedTest(String testName) {
    final normalizedTestName = _normalizeText(testName);
    
    // First try direct mapping through variations
    for (var entry in TestDefinitions.testVariations.entries) {
      if (entry.value.any((variation) => _normalizeText(variation) == normalizedTestName)) {
        // Find the corresponding category and full name
        for (var category in TestDefinitions.predefinedTests.entries) {
          for (var test in category.value.entries) {
            if (test.key == entry.key) {
              return {
                "category": category.key,
                "test_key": test.key,
                "full_name": test.value["full_name"]!,
                "medical_abbreviation": test.value["medical_abbreviation"]!
              };
            }
          }
        }
      }
    }
    
    // If no match found, return it as an "other" category test
    return {
      "category": "other",
      "test_key": _normalizeText(testName).replaceAll(' ', '_'),
      "full_name": testName,
      "medical_abbreviation": testName
    };
  }

  // Process and normalize test data
  static Future<Map<String, dynamic>> normalizeTestData(Map<String, dynamic> apiResponse) async {
    final normalizedData = initializeNormalizedStructure();
    
    apiResponse.forEach((category, data) {
      if (data is Map<String, dynamic>) {
        // Handle summary
        final normalizedCategory = _normalizeCategoryKey(category);
        normalizedData[normalizedCategory]["summary"] = data['summary'] ?? "";
        
        // Handle tests
        if (data['tests'] is Map<String, dynamic>) {
          final tests = data['tests'] as Map<String, dynamic>;
          
          tests.forEach((testName, testValue) {
            final matchedTest = findMatchingPredefinedTest(testName);
            
            if (matchedTest != null) {
              String value;
              if (testValue is Map<String, dynamic>) {
                value = testValue['current_value'].toString();
                // Store reference range if available
                if (testValue['reference_range'] != null) {
                  ReferenceRangeService.storeReferenceRange(
                    matchedTest["test_key"]!,
                    testValue['reference_range'].toString()
                  );
                }
              } else {
                value = testValue.toString();
              }
              
              // Get the target category from the matched test
              final targetCategory = matchedTest["category"]!;
              
              // Create the test entry in the normalized data
              normalizedData[targetCategory]["tests"][matchedTest["test_key"]] = {
                "value": value,
                "full_name": matchedTest["full_name"],
                "medical_abbreviation": matchedTest["medical_abbreviation"],
                "reference_range": testValue['reference_range']?.toString()
              };
              
              print('Processed test "$testName" to "${matchedTest["test_key"]}" in category "$targetCategory"');
            }
          });
        }
      }
    });

    return normalizedData;
  }

  // Debug helper to log matching attempts
  static void _debugMatchAttempt(String original, String normalized, String matchAgainst) {
    print('Matching attempt:');
    print('  Original: $original');
    print('  Normalized: $normalized');
    print('  Against: $matchAgainst');
  }

  // Debug helper to log data structures
  static void logDataStructures(Map<String, dynamic> apiResponse, Map<String, dynamic> normalizedData) {
    print('\nOriginal API Response Structure:');
    print(json.encode(apiResponse));
    
    print('\nNormalized Data Structure with Predefined Tests:');
    print(json.encode(normalizedData));
  }
}