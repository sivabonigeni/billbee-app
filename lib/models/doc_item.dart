import 'customer.dart';
import 'line_item.dart';

class DocItem {
  final String id;
  final String type;
  final Customer customer;
  final String status;
  final DateTime date;
  final List<LineItem> items;
  final bool taxEnabled;
  final double taxPercent;

  const DocItem({
    required this.id,
    required this.type,
    required this.customer,
    required this.status,
    required this.date,
    required this.items,
    this.taxEnabled = true,
    this.taxPercent = 18,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get gst => taxEnabled ? subtotal * (taxPercent / 100) : 0;
  double get total => subtotal + gst;

  DocItem copyWith({String? status, List<LineItem>? items, Customer? customer, bool? taxEnabled, double? taxPercent}) => DocItem(
        id: id,
        type: type,
        customer: customer ?? this.customer,
        status: status ?? this.status,
        date: date,
        items: items ?? this.items,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        taxPercent: taxPercent ?? this.taxPercent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'customer': customer.toJson(),
        'status': status,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'taxEnabled': taxEnabled,
        'taxPercent': taxPercent,
      };

  factory DocItem.fromJson(Map<String, dynamic> json) => DocItem(
        id: json['id'],
        type: json['type'],
        customer: Customer.fromJson(Map<String, dynamic>.from(json['customer'])),
        status: json['status'],
        date: DateTime.parse(json['date']),
        items: (json['items'] as List).map((e) => LineItem.fromJson(Map<String, dynamic>.from(e))).toList(),
        taxEnabled: json['taxEnabled'] ?? true,
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 18,
      );
}
