class ReferenceRangeService {
  static final Map<String, String> _referenceRanges = {};

  static void storeReferenceRange(String testName, String range) {
    _referenceRanges[testName] = range;
    print('Stored reference range for $testName: $range');
  }

  static void storeReferenceRanges(Map<String, dynamic> apiResponse) {
    print('\n--- Starting to store reference ranges ---');
    
    apiResponse.forEach((category, data) {
      if (data is Map<String, dynamic> && 
          data['tests'] is Map<String, dynamic>) {
        final tests = data['tests'] as Map<String, dynamic>;
        
        print('\nCategory: $category');
        tests.forEach((testName, testValue) {
          if (testValue is Map<String, dynamic> && 
              testValue['reference_range'] != null) {
            _referenceRanges[testName] = testValue['reference_range'];
            print('  • $testName: ${testValue['reference_range']}');
          }
        });
      }
    });
    
    print('\nTotal stored reference ranges: ${_referenceRanges.length}');
    print('--- Finished storing reference ranges ---\n');
  }

  static String? getReferenceRange(String testName) {
    final range = _referenceRanges[testName];
    print('Retrieved reference range for $testName: $range');
    return range;
  }

  // Helper method to get all stored ranges
  static Map<String, String> getAllReferenceRanges() {
    print('\nAll stored reference ranges:');
    _referenceRanges.forEach((test, range) {
      print('  • $test: $range');
    });
    return Map<String, String>.from(_referenceRanges);
  }
}