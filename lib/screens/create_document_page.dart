import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../models/customer.dart';
import '../models/line_item.dart';
import '../widgets/action_widgets.dart';
import '../widgets/summary_widgets.dart';
import 'create_customer_page.dart';

class CreateDocumentPage extends StatefulWidget {
  final String type;
  final List<Customer> customers;
  final String nextId;
  final DocItem? initialDocument;
  const CreateDocumentPage({super.key, required this.type, required this.customers, required this.nextId, this.initialDocument});

  @override
  State<CreateDocumentPage> createState() => _CreateDocumentPageState();
}

class _CreateDocumentPageState extends State<CreateDocumentPage> {
  Customer? _selectedCustomer;
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final List<LineItem> _items = [];
  bool _taxEnabled = true;
  late final TextEditingController _taxPercentController;
  final _formKey = GlobalKey<FormState>();
  late List<Customer> _currentCustomers;

  bool get _isEditing => widget.initialDocument != null;

  @override
  void initState() {
    super.initState();
    _currentCustomers = List.from(widget.customers);
    _selectedCustomer = widget.initialDocument?.customer ?? (_currentCustomers.isNotEmpty ? _currentCustomers.first : null);
    _items.addAll(widget.initialDocument?.items ?? const []);
    _taxEnabled = widget.initialDocument?.taxEnabled ?? true;
    _taxPercentController = TextEditingController(text: (widget.initialDocument?.taxPercent ?? 18).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
    final taxPercent = double.tryParse(_taxPercentController.text.trim()) ?? 0;
    final gst = _taxEnabled ? subtotal * (taxPercent / 100) : 0;
    final total = subtotal + gst;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${widget.type}' : 'New ${widget.type}'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Customer Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document #: ${widget.initialDocument?.id ?? widget.nextId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Customer>(
                          isExpanded: true,
                          value: _selectedCustomer,
                          hint: const Text('Select Customer'),
                          decoration: InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: _currentCustomers.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setState(() => _selectedCustomer = value),
                          validator: (val) => val == null ? 'Please select a customer' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: _addNewCustomer,
                        icon: const Icon(Icons.person_add_rounded),
                        tooltip: 'Add New Customer',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Line Items',
              child: Column(
                children: [
                  TextFormField(
                    controller: _itemController,
                    decoration: InputDecoration(labelText: 'Item or Service Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Qty', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Price', prefixText: '₹', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_items.isNotEmpty) ...[
                    const Divider(height: 32),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final item = _items[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text('${item.quantity} × ₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => setState(() => _items.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Taxes & Totals',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include GST', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: _taxEnabled,
                    onChanged: (val) => setState(() => _taxEnabled = val),
                  ),
                  if (_taxEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _taxPercentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'GST Percentage (%)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  const Divider(height: 32),
                  SummaryRow(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
                  SummaryRow(label: 'GST ${_taxEnabled ? "($taxPercent%)" : "(0%)"}', value: '₹${gst.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  SummaryRow(label: 'Grand Total', value: '₹${total.toStringAsFixed(0)}', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _items.isEmpty ? null : _saveDocument,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(_isEditing ? 'Update ${widget.type}' : 'Save ${widget.type}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final Customer? newCustomer = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCustomerPage()),
    );

    if (newCustomer != null) {
      setState(() {
        _currentCustomers.insert(0, newCustomer);
        _selectedCustomer = newCustomer;
      });
    }
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid item details')));
      return;
    }
    setState(() {
      _items.add(LineItem(name: name, quantity: qty, price: price));
      _itemController.clear();
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  void _saveDocument() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) return;

    final taxPercent = double.tryParse(_taxPercentController.text.trim()) ?? 18.0;

    Navigator.pop(
      context,
      DocItem(
        id: widget.initialDocument?.id ?? widget.nextId,
        type: widget.type,
        customer: _selectedCustomer!,
        status: widget.initialDocument?.status ?? (widget.type == 'Estimate' ? 'Pending' : 'Unpaid'),
        date: widget.initialDocument?.date ?? DateTime.now(),
        items: List.of(_items),
        taxEnabled: _taxEnabled,
        taxPercent: taxPercent,
      ),
    );
  }
}
