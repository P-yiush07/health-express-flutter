class CategoryMappings {
  static const Map<String, List<String>> categoryMetrics = {
    'Vitals': [
      'Blood Pressure',
      'Heart Rate',
      'Respiratory Rate',
      'Body Temperature',
      'Oxygen Saturation',
    ],
    'Glucose': [
      'Fasting Blood Sugar',
      'Post Prandial Blood Sugar',
      'HbA1c',
      'Random Blood Sugar',
      'R Blood Sugar',
      'Blood Sugar',
    ],
    'LFT': [
      'ALT',
      'AST',
      'Bilirubin',
      'Albumin',
      'Alkaline Phosphatase',
      'Total Protein',
    ],
    'Vitamins': [
      'Vitamin D',
      'Vitamin B12',
      'Vitamin B6',
      'Folate',
      'Vitamin C',
    ],
    'Thyroid': [
      'TSH',
      'T3',
      'T4',
      'Free T3',
      'Free T4',
    ],
    'CBC': [
      'Hemoglobin',
      'Hematocrit',
      'White Blood Cell Count',
      'Red Blood Cell Count',
      'Platelet Count',
      'MCV',
      'MCH',
      'MCHC',
    ],
  };

  static String? getCategoryForMetric(String metricName) {
    for (var entry in categoryMetrics.entries) {
      if (entry.value.any((metric) => 
          metricName.toLowerCase().contains(metric.toLowerCase()))) {
        return entry.key;
      }
    }
    return null;
  }
}
