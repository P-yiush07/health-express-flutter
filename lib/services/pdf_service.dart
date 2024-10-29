import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFService {
  static Future<String> extractTextFromPDF(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String extractedText = '';

      for (int i = 0; i < document.pages.count; i++) {
        extractedText += PdfTextExtractor(document).extractText(startPageIndex: i);
      }

      document.dispose();
      return extractedText;
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return '';
    }
  }
}
