import 'package:flutter/material.dart';
import '../../models/doc_item.dart';
import '../../widgets/summary_widgets.dart';

class HomeTab extends StatelessWidget {
  final List<DocItem> documents;
  final VoidCallback onQuickCreate;
  const HomeTab({super.key, required this.documents, required this.onQuickCreate});

  @override
  Widget build(BuildContext context) {
    final unpaid = documents.where((e) => e.status == 'Unpaid').fold<double>(0, (s, d) => s + d.total);
    final paid = documents.where((e) => e.status == 'Paid').fold<double>(0, (s, d) => s + d.total);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF5AA0FF)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Built for fast billing', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('Create estimates and invoices in under a minute.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onQuickCreate,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A73E8)),
              child: const Text('Quick create'),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            MetricCard(title: 'Unpaid', value: '₹${unpaid.toStringAsFixed(0)}', color: const Color(0xFFEF4444), icon: Icons.pending_actions),
            MetricCard(title: 'Paid', value: '₹${paid.toStringAsFixed(0)}', color: const Color(0xFF16A34A), icon: Icons.verified),
            MetricCard(title: 'Invoices', value: '${documents.where((e) => e.type == 'Invoice').length}', color: const Color(0xFF1A73E8), icon: Icons.receipt_long),
            MetricCard(title: 'Estimates', value: '${documents.where((e) => e.type == 'Estimate').length}', color: const Color(0xFFF59E0B), icon: Icons.request_quote),
          ],
        ),
      ],
    );
  }
}
