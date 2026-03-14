class Customer {
  final String name;
  final String phone;
  final String businessType;

  const Customer({required this.name, required this.phone, required this.businessType});

  Customer copyWith({String? name, String? phone, String? businessType}) => Customer(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        businessType: businessType ?? this.businessType,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'businessType': businessType,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        name: json['name'],
        phone: json['phone'],
        businessType: json['businessType'],
      );
}
