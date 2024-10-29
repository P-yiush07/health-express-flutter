import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  _MyReportsScreenState createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Map<String, dynamic>> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    
    final pdfPaths = manifestMap.keys
        .where((String key) => key.contains('assets/') && key.endsWith('.pdf'))
        .toList();

    setState(() {
      pdfFiles = pdfPaths.map((path) {
        final name = path.split('/').last;
        return {
          'path': path,
          'name': name,
          'date': ReportDateUtils.generateReportDate(name),
        };
      }).toList();

      // Sort by date in descending order
      pdfFiles.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime)
      );

      // Format dates after sorting
      pdfFiles = pdfFiles.map((file) {
        return {
          ...file,
          'date': ReportDateUtils.formatReportDate(file['date'] as DateTime),
        };
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5c258d),
      ),
      body: ListView.builder(
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          final file = pdfFiles[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF5c258d), size: 40),
              title: Text(
                file['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                file['date'] as String,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF5c258d)),
              onTap: () => _openPdf(file['path'] as String),
            ),
          );
        },
      ),
    );
  }
}
