import 'package:flutter/material.dart';
import '../../models/customer.dart';

class CustomersTab extends StatelessWidget {
  final List<Customer> customers;
  final Future<void> Function() onAddCustomer;
  final Future<void> Function(Customer) onEditCustomer;
  const CustomersTab({
    super.key,
    required this.customers,
    required this.onAddCustomer,
    required this.onEditCustomer,
  });

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Customers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              FilledButton.icon(
                onPressed: onAddCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (customers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No customers yet. Add your first customer to speed up invoices.'),
              ),
            ),
          ...customers.map(
            (c) => Card(
              elevation: 0,
              child: ListTile(
                onTap: () => onEditCustomer(c),
                leading: CircleAvatar(child: Text(c.name.substring(0, 1))),
                title: Text(c.name),
                subtitle: Text('${c.businessType} • ${c.phone}'),
                trailing: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
        ],
      );
}
