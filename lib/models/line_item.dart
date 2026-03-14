class LineItem {
  final String name;
  final int quantity;
  final double price;

  const LineItem({required this.name, required this.quantity, required this.price});

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory LineItem.fromJson(Map<String, dynamic> json) => LineItem(
        name: json['name'],
        quantity: json['quantity'],
        price: (json['price'] as num).toDouble(),
      );
}
