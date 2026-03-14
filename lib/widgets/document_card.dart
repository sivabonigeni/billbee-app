import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doc_item.dart';
import '../models/business_profile.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';

class DocumentCard extends StatelessWidget {
  final DocItem doc;
  final BusinessProfile businessProfile;
  final VoidCallback onConvertEstimate;
  final Function(String) onStatusChange;
  final VoidCallback onOpenDetail;

  const DocumentCard({
    super.key,
    required this.doc,
    required this.businessProfile,
    required this.onConvertEstimate,
    required this.onStatusChange,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(doc.status);
    final isInvoice = doc.type == 'Invoice';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isInvoice ? Colors.blue : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doc.type.toUpperCase(),
                      style: TextStyle(
                        color: isInvoice ? Colors.blue : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doc.status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.customer.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.id} • ${DateFormat('dd MMM yyyy').format(doc.date)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${doc.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIconButton(
                    context,
                    icon: Icons.remove_red_eye_outlined,
                    label: 'Preview',
                    onTap: () => _previewPdf(context),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    context,
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _sharePdf(context),
                  ),
                  const Spacer(),
                  if (doc.type == 'Estimate')
                    TextButton.icon(
                      onPressed: onConvertEstimate,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('To Invoice'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  if (isInvoice)
                    _buildStatusMenu(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onStatusChange,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Unpaid', child: Text('Mark Unpaid')),
        const PopupMenuItem(value: 'Paid', child: Text('Mark Paid')),
        const PopupMenuItem(value: 'Partial', child: Text('Mark Partial')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Paid' => const Color(0xFF16A34A),
      'Unpaid' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
  }

  Future<void> _previewPdf(BuildContext context) async {
    final bytes = await generatePdfBytes(doc, businessProfile);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(doc.id)),
            body: PdfPreview(
              build: (format) => bytes,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final bytes = await generatePdfBytes(doc, businessProfile);
    await Printing.sharePdf(bytes: bytes, filename: '${doc.id}.pdf');
  }
}
