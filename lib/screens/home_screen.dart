import 'package:flutter/material.dart';
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
    await _loadKPIsFromStorage();
    await _loadPdfFiles();

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
      previousReports.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );

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

  void _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Loading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Comparing recent reports...'),
            ],
          ),
        );
      },
    );

    try {
      // Trigger comparison of recent reports
      final comparisonResult = await AIService.compareRecentReports();

      // Close the loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show results in a new dialog
      if (comparisonResult.containsKey('comparison')) {
        _showComparisonDialog(comparisonResult['comparison']);
      } else if (comparisonResult.containsKey('error')) {
        _showErrorDialog(comparisonResult['error']);
      }

      // Reload KPIs from storage after AI update
      await _loadKPIsFromStorage();
    } catch (e) {
      // Handle any errors
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error comparing reports: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<KpiIndicator> _createKPIWidgets(List<Map<String, dynamic>> kpiData) {
    print('Creating KPI widgets with data: $kpiData');

    // Define the required KPI types with their default values
    final requiredKPIs = {
      'Heart Rate': {'unit': 'bpm', 'icon': Icons.favorite, 'color': Colors.redAccent},
      'Blood Pressure': {'unit': 'mmHg', 'icon': Icons.show_chart, 'color': Colors.blueAccent},
      'Blood Sugar': {'unit': 'mg/dL', 'icon': Icons.water_drop, 'color': Colors.orangeAccent},
      'BMI': {'unit': '', 'icon': Icons.person, 'color': Colors.greenAccent},
    };

    return requiredKPIs.entries.map((entry) {
      // Find matching KPI data, ignoring case
      final kpi = kpiData.firstWhere(
        (k) => k['title'].toString().toLowerCase().contains(entry.key.toLowerCase()),
        orElse: () => <String, dynamic>{
          'title': entry.key,
          'value': 'N/A',
          'previousValue': 'N/A',
          'unit': entry.value['unit'],
        },
      );

      print('Found KPI for ${entry.key}: $kpi');

      // Handle special case for Blood Pressure format
      String displayValue = kpi['value']?.toString() ?? 'N/A';
      String displayPrevValue = kpi['previousValue']?.toString() ?? 'N/A';

      return KpiIndicator(
        title: entry.key,
        value: displayValue,
        previousValue: displayPrevValue,
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
        previousValue: 'N/A',
        unit: 'bpm',
        icon: Icons.favorite,
        color: Colors.redAccent
      ),
      KpiIndicator(
        title: 'Blood Pressure',
        value: 'N/A',
        previousValue: 'N/A',
        unit: 'mmHg',
        icon: Icons.show_chart,
        color: Colors.blueAccent
      ),
      KpiIndicator(
        title: 'Blood Sugar',
        value: 'N/A',
        previousValue: 'N/A',
        unit: 'mg/dL',
        icon: Icons.water_drop,
        color: Colors.orangeAccent
      ),
      KpiIndicator(
        title: 'BMI',
        value: 'N/A',
        previousValue: 'N/A',
        unit: '',
        icon: Icons.person,
        color: Colors.greenAccent
      ),
    ];
  }

  void _showComparisonDialog(String comparison) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Comparison'),
          content: SingleChildScrollView(
            child: Text(comparison),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('View History'),
              onPressed: () {
                Navigator.of(context).pop();
                AIService.showStoredValues(context);
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  void _showStoredValues() async {
    await AIService.showStoredValues(context);
    // Refresh KPIs after stored values dialog is closed
    await _loadKPIsFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    String userName = "Asuttosh Dash"; 
    
    const double sectionSpacing = 20.0;

    // Example data source
    final kpiData = [
      {
        'title': 'Heart Rate',
        'currentValue': '72',
        'previousValue': '75',
        'unit': 'bpm',
        'icon': Icons.favorite,
        'color': Colors.redAccent,
      },
      {
        'title': 'Blood Pressure',
        'currentValue': '120/80',
        'previousValue': '115/75',
        'unit': 'mmHg',
        'icon': Icons.show_chart,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Blood Sugar',
        'currentValue': '95',
        'previousValue': '100',
        'unit': 'mg/dL',
        'icon': Icons.water_drop,
        'color': Colors.orangeAccent,
      },
      {
        'title': 'BMI',
        'currentValue': '22.5',
        'previousValue': '23.0',
        'unit': '',
        'icon': Icons.person,
        'color': Colors.greenAccent,
      },
    ];

    return Scaffold(
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: PageStorage(
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
                          userName,
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
                          icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
                          onPressed: _openChatScreen,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.description_outlined, color: Colors.white),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              const SizedBox(height: sectionSpacing),
              if (previousReports.isNotEmpty)
                PreviousReportsList(
                  reports: previousReports,
                  maxReports: 4,
                  onShowMore: _openReportsScreen,
                  openPdf: _openPdf,
                )
              else
                const Center(
                  child: Text(
                    'No previous reports available',
                    style: TextStyle(color: Colors.white)
                  )
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

