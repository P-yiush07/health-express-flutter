import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/report_comparison_service.dart';
import '../widgets/kpi_indicator.dart';
import '../widgets/ai_chat_button.dart';
import '../widgets/reports_button.dart';
import '../painters/background_painter.dart';
import 'report_selection_screen.dart';
import '../widgets/comparison_indicator.dart';
import '../widgets/previous_reports_list.dart';
import 'my_reports_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/kpi_service.dart';
import '../widgets/categories_grid.dart';
import '../utils/date_utils.dart';
import '../services/ai_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/manage_screen_content.dart';
import '../services/report_preference_service.dart';
import '../widgets/report_history_dialog.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageStorageBucket _bucket = PageStorageBucket();
  List<Map<String, dynamic>> previousReports = [];
  bool isLoading = true;
  List<KpiIndicator> kpis = [];
  final _categoriesKey = GlobalKey<CategoriesGridState>();
  late StreamSubscription<void> _refreshSubscription;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
    _setupRefreshListener();
  }

  void _setupRefreshListener() {
    _refreshSubscription = AIService.refreshStream.listen((_) {
      _loadKPIsFromStorage();
      _categoriesKey.currentState?.refreshGrid();
    });
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await AIService.initializeStoredValues();

    // Load active report data if exists
    final activeReport = await ReportPreferenceService.getActiveReport();
    if (activeReport != null) {
      await _loadReportData(activeReport);
    } else {
      await _loadKPIsFromStorage();
    }

    await _loadPdfFiles();

    // Get the log of total reports available

      await ReportComparisonService.getAvailableReportsCount();

    // Load saved category data
    final savedCategoryData = await ReportPreferenceService.getCategoryData();
    if (savedCategoryData.isNotEmpty) {
      await _processCategoriesData(savedCategoryData);
    }

    // Add debug logging for category summaries
    final summaries = await AIService.getStoredCategorySummaries();
    print('Stored category summaries on startup:');
    summaries.forEach((category, summary) {
      print('$category: $summary');
    });
  }

  Future<void> _loadKPIsFromStorage() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First check if there are any stored values
      final storedValues = await AIService.getStoredValues();
      if (storedValues.isEmpty) {
        setState(() {
          kpis = _getDefaultKPIs();
        });
        return;
      }

      final latestKPIs = await KPIService.getLatestKPIs();
      print('Loaded KPIs from storage: $latestKPIs');

      if (latestKPIs.isNotEmpty) {
        final kpiWidgets = _createKPIWidgets(latestKPIs);
        setState(() {
          kpis = kpiWidgets;
        });
      } else {
        print('No KPIs found in storage, using defaults');
        setState(() {
          kpis = _getDefaultKPIs();
        });
      }
    } catch (e) {
      print('Error loading KPIs from storage: $e');
      setState(() {
        kpis = _getDefaultKPIs();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPdfFiles() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final pdfPaths = manifestMap.keys
        .where((String key) => key.contains('assets/') && key.endsWith('.pdf'))
        .toList();

    setState(() {
      previousReports = pdfPaths.map((path) {
        final name = path.split('/').last;
        return {
          'path': path,
          'name': name,
          'date': ReportDateUtils.generateReportDate(name),
        };
      }).toList();

      // Sort by date in descending order
      previousReports.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Format dates after sorting
      previousReports = previousReports.map((report) {
        return {
          ...report,
          'date': ReportDateUtils.formatReportDate(report['date'] as DateTime),
        };
      }).toList();
    });
  }

  void _openChatScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportSelectionScreen(),
      ),
    );
  }

  void _openReportsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyReportsScreen(),
      ),
    );
  }

  Future<void> _openPdf(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
    await tempFile.writeAsBytes(bytes);

    final result = await OpenFile.open(tempFile.path);
    if (result.type != ResultType.done) {
      // Handle error
      print('Error opening file: ${result.message}');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final activeReport = await ReportPreferenceService.getActiveReport();
      if (activeReport == null) {
        throw Exception('No active report selected. Please select a report first.');
      }

      // Debug print
      print('Active report asset path: $activeReport');
      
      final data = await ApiService.fetchMedicalTests();
      print('Received medical tests data: $data');

      // Process data for KPI indicators
      final vitalsData = data['Vitals']?['tests'];
      final kpiData = await _processVitalsForKPIs(vitalsData, data);

      // Update KPIs and Categories simultaneously
      setState(() {
        kpis = _createKPIWidgets(kpiData);
        if (_categoriesKey.currentState != null) {
          _categoriesKey.currentState!.updateCategoryData(data);
          _categoriesKey.currentState!.refreshGrid();
        }
      });

      // Save data in background
      await Future.wait([
        ReportPreferenceService.saveReportData(activeReport, {
          'kpis': kpiData,
          'categories': data,
        }),
        ReportPreferenceService.saveCategoryData(data),
      ]);

    } catch (e) {
      print('Error in _refreshData: $e');
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _processVitalsForKPIs(
      dynamic vitalsData, Map<String, dynamic> fullData) async {
    // Handle the new normalized structure
    final Map<String, dynamic> safeVitalsData = 
        (fullData['vitals']?['tests'] is Map<String, dynamic>) 
        ? fullData['vitals']['tests'] 
        : {};
    
    // Get glucose data from the new structure
    String glucoseValue = 'N/A';
    if (fullData['glucose']?['tests'] != null) {
      final glucoseTests = fullData['glucose']['tests'];
      // Try to get fasting glucose using the predefined test key
      glucoseValue = glucoseTests['fasting_glucose']?['value']?.toString() ?? 'N/A';
    }
    
    // Get previous values from comparison report
    final comparisonReport = await ReportPreferenceService.getComparisonReport();
    Map<String, dynamic> previousValues = {};
    
    if (comparisonReport != null) {
      final reportDataMap = await ReportPreferenceService.getReportDataMap();
      final previousData = reportDataMap[comparisonReport];
      if (previousData != null && previousData['categories'] != null) {
        final prevVitals = previousData['categories']['vitals']?['tests'];
        final prevGlucose = previousData['categories']['glucose']?['tests'];
        
        previousValues = {
          'Heart Rate': prevVitals?['pulse_rate']?['value'],
          'Blood Pressure': prevVitals?['blood_pressure']?['value'],
          'Fasting Glucose': prevGlucose?['fasting_glucose']?['value'],
          'BMI': prevVitals?['bmi']?['value'],
        };
      }
    }

    return [
      {
        'title': 'Heart Rate',
        'value': safeVitalsData['pulse_rate']?['value'] ?? 'N/A',
        'unit': 'bpm',
        'previousValue': previousValues['Heart Rate'],
      },
      {
        'title': 'Blood Pressure',
        'value': safeVitalsData['blood_pressure']?['value'] ?? 'N/A',
        'unit': 'mmHg',
        'previousValue': previousValues['Blood Pressure'],
      },
      {
        'title': 'Fasting Glucose',
        'value': glucoseValue,
        'unit': 'mg/dl',
        'previousValue': previousValues['Fasting Glucose'],
      },
      {
        'title': 'BMI',
        'value': safeVitalsData['bmi']?['value'] ?? 'N/A',
        'unit': 'kg/m2',
        'previousValue': previousValues['BMI'],
      },
    ];
  }

  Future<void> _processCategoriesData(Map<String, dynamic> categories) async {
    try {
      final vitalsData = categories['Vitals']?['tests'];
      final processedKpiData = await _processVitalsForKPIs(vitalsData, categories);
      
      if (mounted) {
        setState(() {
          kpis = _createKPIWidgets(processedKpiData);
        });
      }
    } catch (e) {
      print('Error processing categories data: $e');
    }
  }

  List<KpiIndicator> _createKPIWidgets(List<Map<String, dynamic>> kpiData) {
    final requiredKPIs = {
      'Heart Rate': {
        'unit': 'bpm',
        'icon': Icons.favorite,
        'color': Colors.redAccent
      },
      'Blood Pressure': {
        'unit': 'mmHg',
        'icon': Icons.show_chart,
        'color': Colors.blueAccent
      },
      'Fasting Glucose': {
        'unit': 'mg/dl',
        'icon': Icons.water_drop,
        'color': Colors.orangeAccent
      },
      'BMI': {
        'unit': 'kg/m2',
        'icon': Icons.person,
        'color': Colors.greenAccent
      },
    };

    return requiredKPIs.entries.map((entry) {
      final kpi = kpiData.firstWhere(
        (k) => k['title']
            .toString()
            .toLowerCase()
            .contains(entry.key.toLowerCase()),
        orElse: () => <String, dynamic>{
          'title': entry.key,
          'value': 'N/A',
          'unit': entry.value['unit'],
          'previousValue': null,
        },
      );

      return KpiIndicator(
        title: entry.key,
        value: kpi['value']?.toString() ?? 'N/A',
        previousValue: kpi['previousValue']?.toString(),
        unit: entry.value['unit'] as String,
        icon: entry.value['icon'] as IconData,
        color: entry.value['color'] as Color,
      );
    }).toList();
  }

  List<KpiIndicator> _getDefaultKPIs() {
    return [
      KpiIndicator(
          title: 'Heart Rate',
          value: 'N/A',
          unit: 'bpm',
          icon: Icons.favorite,
          color: Colors.redAccent),
      KpiIndicator(
          title: 'Blood Pressure',
          value: 'N/A',
          unit: 'mmHg',
          icon: Icons.show_chart,
          color: Colors.blueAccent),
      KpiIndicator(
          title: 'Fasting Glucose',
          value: 'N/A',
          unit: 'mg/dL',
          icon: Icons.water_drop,
          color: Colors.orangeAccent),
      KpiIndicator(
          title: 'BMI',
          value: 'N/A',
          unit: '',
          icon: Icons.person,
          color: Colors.greenAccent),
    ];
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(error),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStoredValues() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportHistoryDialog(
          onHistoryDeleted: () async {
            // Get the active report path first
            final activeReport =
                await ReportPreferenceService.getActiveReport();
            if (activeReport != null) {
              // Refresh the data in HomeScreen
              _loadReportData(activeReport);
            }
            setState(() {
              kpis = _getDefaultKPIs();
            });
            // Clear category data
            if (_categoriesKey.currentState != null) {
              _categoriesKey.currentState!.updateCategoryData({});
              _categoriesKey.currentState!.refreshGrid();
            }
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return PageStorage(
          bucket: _bucket,
          child: ListView(
            key: const PageStorageKey<String>('homeScreenListView'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Asuttosh Dash",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _refreshData,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.smart_toy_outlined,
                              color: Colors.white),
                          onPressed: _openChatScreen,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.description_outlined,
                              color: Colors.white),
                          onPressed: _openReportsScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(
                            Icons.history,
                            color: Colors.white70,
                            size: 14,
                          ),
                          label: const Text(
                            'View History',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: _showStoredValues,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    isLoading
                        ? const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Loading KPIs...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: kpis.length,
                            itemBuilder: (context, index) => kpis[index],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CategoriesGrid(key: _categoriesKey),
              ),
              const SizedBox(height: 20),
              if (previousReports.isNotEmpty)
                PreviousReportsList(
                  reports: previousReports,
                  maxReports: 4,
                  onShowMore: _openReportsScreen,
                  openPdf: _openPdf,
                )
              else
                const Center(
                    child: Text('No previous reports available',
                        style: TextStyle(color: Colors.white))),
              const SizedBox(height: 30),
            ],
          ),
        );
      case 1:
        return ManageScreenContent(
          onReportChanged: (String reportPath) {
            _loadReportData(reportPath);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: _getSelectedScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6B4DE6), // Deep purple
              Color(0xFF9C42E3), // Medium purple
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Manage',
            ),
          ],
          currentIndex: _selectedIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<void> _loadReportData(String reportPath) async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final reportData = await ReportPreferenceService.getReportDataMap();
      final data = reportData[reportPath];

      if (data != null) {
        if (data['categories'] != null) {
          final categoryData = Map<String, dynamic>.from(data['categories']);
          await ReportPreferenceService.saveCategoryData(categoryData);
          await _processCategoriesData(categoryData);
        }
      } else {
        if (mounted) {
          setState(() {
            kpis = _getDefaultKPIs();
          });
        }
        await ReportPreferenceService.clearCategoryData();
        if (_categoriesKey.currentState != null) {
          _categoriesKey.currentState!.updateCategoryData({});
          _categoriesKey.currentState!.refreshGrid();
        }
      }
    } catch (e) {
      print('Error loading report data: $e');
      _showErrorDialog('Error loading report data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
