import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../widgets/action_widgets.dart';

class CreateCustomerPage extends StatefulWidget {
  final Customer? customer;
  const CreateCustomerPage({super.key, this.customer});

  @override
  State<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends State<CreateCustomerPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _typeController = TextEditingController(text: widget.customer?.businessType ?? 'Service');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Customer details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Customer name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(labelText: 'Business type', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter type' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.customer == null ? 'Save customer' : 'Update customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final type = _typeController.text.trim();
    Navigator.pop(context, Customer(name: name, phone: phone, businessType: type));
  }
}
