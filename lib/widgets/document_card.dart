import 'package:flutter/material.dart';
import '../models/doc_item.dart';

class DocumentCard extends StatelessWidget {
  final DocItem document;
  final VoidCallback? onConvertEstimate;
  final ValueChanged<String>? onStatusChange;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onPdfPreview;
  const DocumentCard({
    super.key,
    required this.document,
    this.onConvertEstimate,
    this.onStatusChange,
    this.onOpen,
    this.onShare,
    this.onPdfPreview,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (document.status) {
      'Paid' => const Color(0xFF16A34A),
      'Unpaid' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(document.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(document.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
              )
            ]),
            const SizedBox(height: 8),
            Text('${document.type} • ${document.customer.name}'),
            const SizedBox(height: 8),
            Text('₹${document.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: onPdfPreview,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
              FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
              if (onConvertEstimate != null)
                FilledButton.tonalIcon(onPressed: onConvertEstimate, icon: const Icon(Icons.swap_horiz), label: const Text('To Invoice')),
              if (onStatusChange != null && document.type == 'Invoice')
                PopupMenuButton<String>(
                  onSelected: onStatusChange,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Unpaid', child: Text('Mark Unpaid')),
                    PopupMenuItem(value: 'Paid', child: Text('Mark Paid')),
                    PopupMenuItem(value: 'Partial', child: Text('Mark Partial')),
                  ],
                  child: const Chip(label: Text('Status')),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
