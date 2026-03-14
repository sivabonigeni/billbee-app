import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/doc_item.dart';
import '../models/business_profile.dart';
import '../services/pdf_service.dart';

class PdfViewerPage extends StatelessWidget {
  final DocItem document;
  final BusinessProfile profile;
  const PdfViewerPage({super.key, required this.document, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.id)),
      body: PdfPreview(
        build: (format) => generatePdfBytes(document, profile),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
