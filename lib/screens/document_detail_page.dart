import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/doc_item.dart';
import '../models/arguments.dart';
import '../widgets/action_widgets.dart';
import '../widgets/summary_widgets.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_page.dart';
import 'create_document_page.dart';

class DocumentDetailPage extends StatefulWidget {
  final DocumentDetailArgs args;
  const DocumentDetailPage({super.key, required this.args});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late String _status;

  DocItem get _document => widget.args.document;

  @override
  void initState() {
    super.initState();
    _status = _document.status;
  }

  @override
  Widget build(BuildContext context) {
    final currentDoc = _document.copyWith(status: _status);
    return Scaffold(
      appBar: AppBar(
        title: Text(_document.id),
        actions: [
          IconButton(
            tooltip: 'Delete document',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete document?'),
                  content: Text('This will remove ${_document.id} from BillBee.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                navigator.pop(const DocumentActionResult(delete: true));
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: '${_document.type} overview',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customer: ${_document.customer.name}'),
              Text('Phone: ${_document.customer.phone}'),
              Text('Date: ${_document.date.toLocal()}'.split('.').first),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: (_document.type == 'Invoice'
                        ? ['Unpaid', 'Paid', 'Partial']
                        : ['Pending', 'Approved', 'Rejected'])
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Items',
            child: Column(
                children: _document.items
                    .map((i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(i.name),
                        subtitle: Text('${i.quantity} × ₹${i.price.toStringAsFixed(0)}'),
                        trailing: Text('₹${i.total.toStringAsFixed(0)}')))
                    .toList()),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Totals',
            child: Column(children: [
              SummaryRow(label: 'Subtotal', value: '₹${_document.subtotal.toStringAsFixed(0)}'),
              SummaryRow(label: _document.taxEnabled ? 'GST (${_document.taxPercent.toStringAsFixed(1)}%)' : 'GST (Disabled)', value: '₹${_document.gst.toStringAsFixed(0)}'),
              const Divider(),
              SummaryRow(label: 'Total', value: '₹${_document.total.toStringAsFixed(0)}', bold: true),
            ]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final edited = await Navigator.push<DocItem>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDocumentPage(
                        type: _document.type,
                        customers: widget.args.customers,
                        nextId: _document.id,
                        initialDocument: currentDoc,
                      ),
                    ),
                  );
                  if (edited != null) {
                    navigator.pop(DocumentActionResult(document: edited));
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit document'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerPage(document: currentDoc, profile: widget.args.businessProfile)));
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Preview PDF'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final bytes = await generatePdfBytes(currentDoc, widget.args.businessProfile);
                  await Printing.sharePdf(bytes: bytes, filename: '${currentDoc.id}.pdf');
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share now'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, DocumentActionResult(document: currentDoc)),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
