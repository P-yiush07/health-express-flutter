class MedicalTestResult {
  final String name;
  final double value;
  final String unit;
  final String status;
  final String interpretation;
  final double? normalRangeMin;
  final double? normalRangeMax;

  MedicalTestResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.interpretation,
    this.normalRangeMin,
    this.normalRangeMax,
  });

  factory MedicalTestResult.fromJson(Map<String, dynamic> json) {
    return MedicalTestResult(
      name: json['name'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      status: json['status'],
      interpretation: json['interpretation'],
      normalRangeMin: json['normalRangeMin']?.toDouble(),
      normalRangeMax: json['normalRangeMax']?.toDouble(),
    );
  }
}

