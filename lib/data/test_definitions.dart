class TestDefinitions {
  // Common variations for test names
  static const Map<String, List<String>> testVariations = {
    // Vitals
    'blood_pressure': ['blood pressure', 'bp'],
    'height': ['height', 'ht', 'stature'],
    'weight': ['weight', 'wt', 'body weight'],
    'bmi': ['body mass index', 'bmi', 'quetelet index'],
    
    // Glucose
    'fasting_glucose': ['fasting glucose', 'fbs', 'fasting blood sugar', 'glucose fasting'],
    'postprandial_glucose': ['postprandial glucose', 'ppbs', 'pp glucose', 'glucose pp'],
    'hba1c': ['hba1c', 'glycated hemoglobin', 'a1c', 'glycohemoglobin'],
    'glucose': ['glucose', 'glucose fasting', 'glucose postprandial'],
    
    // CBC
    'hemoglobin': ['hemoglobin', 'hb', 'haemoglobin'],
    'rbc_count': ['red blood cell count', 'rbc', 'red blood cells', 'red blood cell count', 'rbc count'],
    'total_wbc': ['total white blood cells', 'wbc', 'leukocytes', 'white blood cell count'],
    'mcv': ['mean corpuscular volume', 'mcv', 'mean cell volume'],
    'mch': ['mean corpuscular hemoglobin', 'mch', 'mean cell hemoglobin'],
    'mchc': ['mean corpuscular hemoglobin concentration', 'mchc', 'mean cell hemoglobin concentration'],
    'segmented_neutrophils': ['segmented neutrophil percentage', 'segmented neutrophils', 'seg neut%', 'Segmented Neutrophils %'],
    'neutrophils': ['neutrophil percentage', 'neutrophils', 'neut'],
    'lymphocytes': ['lymphocyte percentage', 'lymphocytes', 'lymph'],
    'monocytes': ['monocyte percentage', 'monocytes', 'mono'],
    'eosinophils': ['eosinophil percentage', 'eosinophils', 'eos'],
    'basophils': ['basophil percentage', 'basophils', 'baso'],
    'absoloute_leucocyte_count_nutrophils': ['absolute leucocyte count neutrophils', 'abs neutrophils', 'abs neutrophil count', 'Absolute Leucocyte Count Neutrophils'],
    'absoloute_leucocyte_count_lymphocytes': ['absolute leucocyte count lymphocytes', 'abs lymphocytes', 'abs lymphocyte count', 'Absolute Leucocyte Count Lymphocytes'],
    'absoloute_leucocyte_count_monocytes': ['absolute leucocyte count monocytes', 'abs monocytes', 'abs monocyte count', 'Absolute Leucocyte Count Monocytes'],
    'absoloute_leucocyte_count_eosinophils': ['absolute leucocyte count eosinophils', 'abs eosinophils', 'abs eosinophil count', 'Absolute Leucocyte Count Eosinophils'],
    'absoloute_leucocyte_count_basophils': ['absolute leucocyte count basophils', 'abs basophils', 'abs basophil count', 'Absolute Leucocyte Count Basophils'],
    'platelets': ['platelet count', 'plt', 'thrombocytes'],
    
    // Kidney Functions
    'serum_urea': ['serum urea', 'urea', 'blood urea'],
    'serum_sodium': ['serum sodium', 'sodium', 'na+'],
    'serum_potassium': ['serum potassium', 'potassium', 'k+'],
    'serum_chloride': ['serum chloride', 'chloride', 'cl-'],
    'specific_gravity': ['specific gravity', 'urine specific gravity'],
    
    // LFT
    'serum_calcium': ['serum total calcium', 'calcium', 'total calcium', 'serum calcium'],

    // Thyroid
    'tsh': ['thyroid stimulating hormone', 'tsh', 'thyroid stimulating hormone'],
    'T3, Total': ['t3, total', 't3', 't3, total'],
    'T4, Total': ['t4, total', 't4', 't4, total'],
  };

  static const Map<String, Map<String, Map<String, String>>> predefinedTests = {
    "vitals": {
      "blood_pressure": {
        "full_name": "Blood Pressure",
        "medical_abbreviation": "BP"
      },
      "height": {
        "full_name": "Height",
        "medical_abbreviation": "Ht"
      },
      "weight": {
        "full_name": "Weight",
        "medical_abbreviation": "Wt"
      },
      "bmi": {
        "full_name": "Body Mass Index",
        "medical_abbreviation": "BMI"
      }
    },
    "glucose": {
      "fasting_glucose": {
        "full_name": "Fasting Blood Glucose",
        "medical_abbreviation": "FBS"
      },
      "postprandial_glucose": {
        "full_name": "Postprandial Blood Glucose",
        "medical_abbreviation": "PPBS"
      },
      "hba1c": {
        "full_name": "HbA1C",
        "medical_abbreviation": "HbA1C"
      },
      "glucose": {
        "full_name": "Glucose",
        "medical_abbreviation": "GLU"
      },
    },
    "cbc": {
      "hemoglobin": {
        "full_name": "Hemoglobin",
        "medical_abbreviation": "Hb"
      },
      "rbc_count": {
        "full_name": "Red Blood Cell Count",
        "medical_abbreviation": "RBC"
      },
      "total_wbc": {
        "full_name": "Total White Blood Cells",
        "medical_abbreviation": "WBC"
      },
      "mcv": {
        "full_name": "Mean Corpuscular Volume",
        "medical_abbreviation": "MCV"
      },
      "mch": {
        "full_name": "Mean Corpuscular Hemoglobin",
        "medical_abbreviation": "MCH"
      },
      "mchc": {
        "full_name": "Mean Corpuscular Hemoglobin Concentration",
        "medical_abbreviation": "MCHC"
      },
      'segmented_neutrophils': {
        "full_name": "Segmented Neutrophil Percentage",
        "medical_abbreviation": "Seg Neut%"
      },
      "neutrophils": {
        "full_name": "Neutrophil Percentage",
        "medical_abbreviation": "Neut%"
      },
      "lymphocytes": {
        "full_name": "Lymphocyte Percentage",
        "medical_abbreviation": "Lymph%"
      },
      "monocytes": {
        "full_name": "Monocyte Percentage",
        "medical_abbreviation": "Mono%"
      },
      "eosinophils": {
        "full_name": "Eosinophil Percentage",
        "medical_abbreviation": "Eos%"
      },
      "basophils": {
        "full_name": "Basophil Percentage",
        "medical_abbreviation": "Baso%"
      },
      "absoloute_leucocyte_count_nutrophils": {
        "full_name": "Absolute Leucocyte Count Neutrophils",
        "medical_abbreviation": "ALCN"
      },
      "absoloute_leucocyte_count_lymphocytes": {
        "full_name": "Absolute Leucocyte Count Lymphocytes",
        "medical_abbreviation": "ALCL"
      },
      "absoloute_leucocyte_count_monocytes": {
        "full_name": "Absolute Leucocyte Count Monocytes",
        "medical_abbreviation": "ALCM"
      },
      "absoloute_leucocyte_count_eosinophils": {
        "full_name": "Absolute Leucocyte Count Eosinophils",
        "medical_abbreviation": "ALCE"
      },
      "absoloute_leucocyte_count_basophils": {
        "full_name": "Absolute Leucocyte Count Basophils",
        "medical_abbreviation": "ALCB"
      },
      "platelets": {
        "full_name": "Platelet Count",
        "medical_abbreviation": "PLT"
      }
    },
    "kidney_functions": {
      "serum_urea": {
        "full_name": "Serum Urea",
        "medical_abbreviation": "Urea"
      },
      "serum_sodium": {
        "full_name": "Serum Sodium",
        "medical_abbreviation": "Na+"
      },
      "serum_potassium": {
        "full_name": "Serum Potassium",
        "medical_abbreviation": "K+"
      },
      "serum_chloride": {
        "full_name": "Serum Chloride",
        "medical_abbreviation": "Cl-"
      },
      "specific_gravity": {
        "full_name": "Specific Gravity",
        "medical_abbreviation": "SG"
      }
    },
    "lft": {
      "serum_calcium": {
        "full_name": "Serum Total Calcium",
        "medical_abbreviation": "Ca"
      }
    },
    "thyroid": {
      "tsh": {
        "full_name": "Thyroid Stimulating Hormone",
        "medical_abbreviation": "TSH"
      },
      "T3, Total": {
        "full_name": "T3, Total",
        "medical_abbreviation": "T3, Total"
      },
      "T4, Total": {
        "full_name": "T4, Total",
        "medical_abbreviation": "T4, Total"
      }
    }
  };
}
