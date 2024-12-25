class TestDefinitions {
 static final Map<String, String> _testInfo = {
    'Blood Pressure': 'A vital cardiovascular measurement that records the force of blood against arterial walls in millimeters of mercury (mmHg). Systolic pressure represents heart contraction force, while diastolic indicates arterial pressure between beats.',
    
    'BMI': 'A standardized numerical measurement of body composition calculated using weight and height (kg/m²). This index helps assess whether an individuals weight falls within healthy parameters for their height.',
    
    'HbA1C': 'Glycated hemoglobin test measuring average blood glucose levels over 2-3 months. This test reflects long-term blood sugar control and is crucial for diabetes diagnosis and monitoring.',
    
    'Fasting Blood Glucose': 'Measures blood sugar levels after an 8-hour fast. This test is fundamental for diabetes screening and diagnosis, reflecting how well the body manages glucose without food intake.',
    
    'Postprandial Glucose': 'Measures blood glucose levels 2 hours after eating. This test evaluates how efficiently your body processes glucose after meals, helping detect diabetes and insulin resistance.',
    
    'Hemoglobin': 'Measures the oxygen-carrying protein concentration in red blood cells. This test is crucial for diagnosing anemia and evaluating oxygen transport capacity in blood.',
    
    'Total Leukocyte Count': 'Quantifies white blood cells in blood, indicating immune system strength and potential infections. Higher counts often suggest infection or inflammation, while lower counts may indicate immune system issues.',
    
    'Mean Corpuscular Volume': 'Measures the average size of red blood cells. This helps classify types of anemia and evaluate overall red blood cell health.',
    
    'Platelet Count': 'Measures blood-clotting cells (thrombocytes) concentration. Essential for evaluating bleeding risks and clotting disorders, with both high and low counts indicating potential health issues.',
    
    'Serum Calcium': 'Measures calcium levels in blood, crucial for bone health, muscle function, and nerve signaling. Abnormal levels can indicate parathyroid disorders, bone diseases, or kidney problems.',
    
    'Serum Urea': 'Measures waste product levels from protein metabolism. Important indicator of kidney function and protein breakdown in the body.',
    
    'Serum Sodium': 'Measures this essential electrolyte that regulates blood pressure, nerve function, and fluid balance. Critical for assessing hydration and kidney function.',
    
    'Serum Potassium': 'Measures this crucial electrolyte needed for proper heart rhythm and muscle contractions. Vital for cardiac function and neuromuscular coordination.',
    
    'Serum Chloride': 'Measures this important electrolyte that helps maintain proper blood volume, pressure, and pH. Key indicator of acid-base balance and kidney function.',
    
    'Specific Gravity': 'Measures urine concentration, indicating how well kidneys concentrate or dilute urine. Helps evaluate kidney function and hydration status.',
    
    'Neutrophil Percentage': 'Measures the proportion of neutrophils (type of white blood cell) in blood. Important for assessing bacterial infections and immune system response.',
    
    'Lymphocyte Percentage': 'Measures the proportion of lymphocytes (immune cells) in blood. Crucial for evaluating viral infections and immune system health.',
    
    'Monocyte Percentage': 'Measures the proportion of monocytes (type of white blood cell) in blood. Important for assessing chronic infections and inflammatory conditions.',
    
    'Eosinophil Percentage': 'Measures the proportion of eosinophils in blood. Elevated levels often indicate allergic reactions or parasitic infections.',
    
    'Basophil Percentage': 'Measures the proportion of basophils in blood. Important for evaluating inflammatory reactions and allergic responses.',

    'Fasting Glucose': 'Measures blood glucose levels after an 8-hour fasting period. This test is a key tool in diagnosing diabetes and assessing how effectively the body regulates blood sugar in the absence of food.',
  
    'Serum Total Calcium': 'Measures the total amount of calcium in the blood, including both bound and free calcium. It is essential for bone health, muscle function, nerve signaling, and proper heart rhythm. Abnormal levels can indicate issues such as kidney disease or parathyroid disorders.'
  };

  static String? getTestInfo(String testName) {
    return _testInfo[testName];
  }

  static bool hasTestInfo(String testName) {
    return _testInfo.containsKey(testName);
  }
} 