import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/doc_item.dart';
import '../models/business_profile.dart';
import '../models/arguments.dart';
import '../services/storage_service.dart';
import '../widgets/action_widgets.dart';
import 'tabs/home_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/customers_tab.dart';
import 'tabs/settings_tab.dart';
import 'create_document_page.dart';
import 'document_detail_page.dart';
import 'create_customer_page.dart';

class BillBeeHome extends StatefulWidget {
  const BillBeeHome({super.key});

  @override
  State<BillBeeHome> createState() => _BillBeeHomeState();
}

class _BillBeeHomeState extends State<BillBeeHome> {
  int _index = 0;
  bool _loading = true;
  List<Customer> _customers = [];
  List<DocItem> _documents = [];
  int _estimateCounter = 1002;
  int _invoiceCounter = 2036;
  BusinessProfile _businessProfile = const BusinessProfile();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await BillBeeStore.load();
    final profile = await BillBeeStore.loadBusinessProfile();
    setState(() {
      _customers = data.customers;
      _documents = data.documents;
      _estimateCounter = data.estimateCounter;
      _invoiceCounter = data.invoiceCounter;
      _businessProfile = profile;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await BillBeeStore.save(_customers, _documents, _estimateCounter, _invoiceCounter);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      HomeTab(documents: _documents, onQuickCreate: _showCreateSheet),
      DocumentsTab(
        documents: _documents,
        businessProfile: _businessProfile,
        onConvertEstimate: _convertEstimateToInvoice,
        onStatusChange: _changeStatus,
        onOpenDetail: _openDetail,
        onCreateNew: _showCreateSheet,
      ),
      CustomersTab(customers: _customers, onAddCustomer: _openAddCustomer, onEditCustomer: _openEditCustomer),
      SettingsTab(profile: _businessProfile, onSave: _saveBusinessProfile),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4B400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('B', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black))),
            ),
            const SizedBox(width: 10),
            const Text('BillBee', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: pages[_index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create new', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateDocument('Estimate');
                },
                child: const CreateActionTile(
                  icon: Icons.request_quote,
                  title: 'New Estimate',
                  subtitle: 'Send a quick quote on WhatsApp',
                  color: Color(0xFFF4B400),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateDocument('Invoice');
                },
                child: const CreateActionTile(
                  icon: Icons.receipt_long,
                  title: 'New Invoice',
                  subtitle: 'Create and share a professional invoice',
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDocument(String type) async {
    final created = await Navigator.push<DocItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDocumentPage(
          type: type,
          customers: _customers,
          nextId: type == 'Estimate' ? 'EST-$_estimateCounter' : 'INV-$_invoiceCounter',
        ),
      ),
    );

    if (created != null) {
      setState(() {
        // Ensure new customer is added to the list if created inline
        final exists = _customers.any((c) => c.phone == created.customer.phone);
        if (!exists) {
          _customers.insert(0, created.customer);
        }
        
        _documents.insert(0, created);
        if (type == 'Estimate') {
          _estimateCounter++;
        } else {
          _invoiceCounter++;
        }
        _index = 1;
      });
      await _persist();
    }
  }

  Future<void> _convertEstimateToInvoice(DocItem estimate) async {
    final invoice = DocItem(
      id: 'INV-${_invoiceCounter++}',
      type: 'Invoice',
      customer: estimate.customer,
      status: 'Unpaid',
      date: DateTime.now(),
      items: estimate.items,
    );
    setState(() => _documents.insert(0, invoice));
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${estimate.id} converted to ${invoice.id}')));
    }
  }

  Future<void> _changeStatus(DocItem doc, String newStatus) async {
    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx == -1) return;
    setState(() => _documents[idx] = doc.copyWith(status: newStatus));
    await _persist();
  }

  Future<void> _openDetail(DocItem doc) async {
    final result = await Navigator.push<DocumentActionResult>(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailPage(args: DocumentDetailArgs(document: doc, customers: _customers, businessProfile: _businessProfile))),
    );
    if (result == null) return;

    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx == -1) return;

    if (result.delete) {
      setState(() => _documents.removeAt(idx));
      await _persist();
      return;
    }

    if (result.document != null) {
      setState(() => _documents[idx] = result.document!);
      await _persist();
    }
  }

  Future<void> _openAddCustomer() async {
    final created = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCustomerPage()),
    );
    if (created != null) {
      setState(() {
        _customers = [created, ..._customers];
      });
      await _persist();
    }
  }

  Future<void> _openEditCustomer(Customer customer) async {
    final updated = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => CreateCustomerPage(customer: customer)),
    );
    if (updated != null) {
      final customerIdx = _customers.indexWhere((c) => c.name == customer.name && c.phone == customer.phone);
      if (customerIdx != -1) {
        setState(() {
          _customers[customerIdx] = updated;
          _documents = _documents
              .map((d) => d.customer.name == customer.name && d.customer.phone == customer.phone ? d.copyWith(customer: updated) : d)
              .toList();
        });
        await _persist();
      }
    }
  }

  Future<void> _saveBusinessProfile(BusinessProfile profile) async {
    setState(() => _businessProfile = profile);
    await BillBeeStore.saveBusinessProfile(profile);
  }
}
