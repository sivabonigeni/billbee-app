import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../widgets/empty_state.dart';

class CustomersTab extends StatefulWidget {
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
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = widget.customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Customers',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
              ),
              IconButton.filledTonal(
                onPressed: widget.onAddCustomer,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: 'Add Customer',
              ),
            ],
          ),
        ),
        if (widget.customers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
                ),
              ),
            ),
          ),
        Expanded(
          child: widget.customers.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No Customers Yet',
                  subtitle: 'Add your customers to quickly create invoices and estimates for them.',
                  actionLabel: 'Add First Customer',
                  onAction: widget.onAddCustomer,
                )
              : filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
                          const SizedBox(height: 16),
                          Text(
                            'No results for "$_searchQuery"',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = filteredCustomers[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () => widget.onEditCustomer(c),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  c.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.businessType,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(c.phone, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
