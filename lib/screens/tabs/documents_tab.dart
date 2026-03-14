import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/doc_item.dart';
import '../../models/business_profile.dart';
import '../../widgets/document_card.dart';
import '../../services/pdf_service.dart';
import '../pdf_viewer_page.dart';

class DocumentsTab extends StatelessWidget {
  final List<DocItem> documents;
  final BusinessProfile businessProfile;
  final Future<void> Function(DocItem) onConvertEstimate;
  final Future<void> Function(DocItem, String) onStatusChange;
  final Future<void> Function(DocItem) onOpenDetail;
  const DocumentsTab({
    super.key,
    required this.documents,
    required this.businessProfile,
    required this.onConvertEstimate,
    required this.onStatusChange,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...documents.map((doc) => DocumentCard(
              document: doc,
              onOpen: () => onOpenDetail(doc),
              onPdfPreview: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerPage(document: doc, profile: businessProfile)));
              },
              onShare: () async {
                final bytes = await generatePdfBytes(doc, businessProfile);
                await Printing.sharePdf(bytes: bytes, filename: '${doc.id}.pdf');
              },
              onConvertEstimate: doc.type == 'Estimate' ? () => onConvertEstimate(doc) : null,
              onStatusChange: (status) => onStatusChange(doc, status),
            )),
      ],
    );
  }
}
