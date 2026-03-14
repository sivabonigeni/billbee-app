import 'package:flutter/material.dart';
import '../models/doc_item.dart';
import '../models/customer.dart';
import '../models/line_item.dart';
import '../widgets/action_widgets.dart';
import '../widgets/summary_widgets.dart';

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
  late Customer _selectedCustomer;
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final List<LineItem> _items = [];
  bool _taxEnabled = true;
  late final TextEditingController _taxPercentController;

  bool get _isEditing => widget.initialDocument != null;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialDocument?.customer ?? widget.customers.first;
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
    final taxEnabled = _taxEnabled;
    final taxPercent = double.tryParse(_taxPercentController.text.trim()) ?? 0;
    final gst = taxEnabled ? subtotal * (taxPercent / 100) : 0;
    final total = subtotal + gst;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit ${widget.type}' : 'New ${widget.type}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionCard(
          title: '${widget.type} details',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Number: ${widget.initialDocument?.id ?? widget.nextId}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder()),
              items: widget.customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} • ${c.phone}'))).toList(),
              onChanged: (value) => setState(() => _selectedCustomer = value!),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Add line item',
          child: Column(children: [
            TextField(controller: _itemController, decoration: const InputDecoration(labelText: 'Item / Service', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add item'))),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Items',
          child: _items.isEmpty
              ? const Text('No items yet.')
              : Column(
                  children: _items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final i = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.name),
                      subtitle: Text('${i.quantity} × ₹${i.price.toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${i.total.toStringAsFixed(0)}'),
                          IconButton(
                            onPressed: () => setState(() => _items.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Tax',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable GST'),
                value: _taxEnabled,
                onChanged: (value) => setState(() => _taxEnabled = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _taxPercentController,
                enabled: _taxEnabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Summary',
          child: Column(children: [
            SummaryRow(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
            SummaryRow(label: _taxEnabled ? 'GST (${taxPercent.toStringAsFixed(1)}%)' : 'GST (Disabled)', value: '₹${gst.toStringAsFixed(0)}'),
            const Divider(),
            SummaryRow(label: 'Total', value: '₹${total.toStringAsFixed(0)}', bold: true),
          ]),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _items.isEmpty ? null : _saveDocument, child: Text(_isEditing ? 'Update ${widget.type}' : 'Save ${widget.type}')),
      ]),
    );
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0 || price <= 0) return;
    setState(() {
      _items.add(LineItem(name: name, quantity: qty, price: price));
      _itemController.clear();
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  void _saveDocument() {
    Navigator.pop(
      context,
      DocItem(
        id: widget.initialDocument?.id ?? widget.nextId,
        type: widget.type,
        customer: _selectedCustomer,
        status: widget.initialDocument?.status ?? (widget.type == 'Estimate' ? 'Pending' : 'Unpaid'),
        date: widget.initialDocument?.date ?? DateTime.now(),
        items: List.of(_items),
        taxEnabled: _taxEnabled,
        taxPercent: double.tryParse(_taxPercentController.text.trim()) ?? 18,
      ),
    );
  }
}
