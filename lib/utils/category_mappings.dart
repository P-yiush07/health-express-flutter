class CategoryMappings {
  static String getCategoryForMetric(String metricName, Map<String, dynamic> apiData) {
    // Check each category's tests in the API response
    for (var entry in apiData.entries) {
      final categoryName = entry.key;
      final categoryData = entry.value as Map<String, dynamic>;
      
      if (categoryData['tests'] != null) {
        final tests = categoryData['tests'] as Map<String, dynamic>;
        
        // Check if the metric name exists in this category's tests
        if (tests.containsKey(metricName)) {
          return categoryName;
        }
        
        // Check nested objects (like Serum Electrolytes)
        for (var test in tests.entries) {
          if (test.value is Map) {
            final nestedTests = test.value as Map<String, dynamic>;
            if (nestedTests.containsKey(metricName)) {
              return categoryName;
            }
          }
        }
      }
    }
    
    return 'Other';
  }
}
