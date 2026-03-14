import 'package:flutter/material.dart';
import '../../models/doc_item.dart';
import '../../models/business_profile.dart';
import '../../widgets/document_card.dart';
import '../../widgets/empty_state.dart';

class DocumentsTab extends StatefulWidget {
  final List<DocItem> documents;
  final BusinessProfile businessProfile;
  final Function(DocItem) onConvertEstimate;
  final Function(DocItem, String) onStatusChange;
  final Function(DocItem) onOpenDetail;
  final VoidCallback onCreateNew;

  const DocumentsTab({
    super.key,
    required this.documents,
    required this.businessProfile,
    required this.onConvertEstimate,
    required this.onStatusChange,
    required this.onOpenDetail,
    required this.onCreateNew,
  });

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  String _filter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.documents.where((doc) {
      final matchesFilter = _filter == 'All' || doc.type == _filter;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = doc.id.toLowerCase().contains(query) ||
          doc.customer.name.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Documents',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All'), icon: Icon(Icons.all_inclusive_rounded, size: 14)),
                    ButtonSegment(value: 'Invoice', label: Text('Invoices'), icon: Icon(Icons.receipt_long_rounded, size: 14)),
                    ButtonSegment(value: 'Estimate', label: Text('Estimates'), icon: Icon(Icons.request_quote_rounded, size: 14)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (val) => setState(() => _filter = val.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.documents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by ID or Customer...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        Expanded(
          child: widget.documents.isEmpty
              ? EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No Documents Yet',
                  subtitle: 'Start creating estimates and invoices for your customers.',
                  actionLabel: 'Create New',
                  onAction: widget.onCreateNew,
                )
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
                          const SizedBox(height: 16),
                          Text(
                            'No documents found for "$_searchQuery"',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DocumentCard(
                            doc: doc,
                            businessProfile: widget.businessProfile,
                            onConvertEstimate: () => widget.onConvertEstimate(doc),
                            onStatusChange: (status) => widget.onStatusChange(doc, status),
                            onOpenDetail: () => widget.onOpenDetail(doc),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
