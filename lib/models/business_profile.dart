class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String gstin;
  final String upiId;
  final String address;
  final String paymentInstructions;
  final String footerNote;
  final String brandColorHex;

  const BusinessProfile({
    this.businessName = '',
    this.ownerName = '',
    this.phone = '',
    this.email = '',
    this.gstin = '',
    this.upiId = '',
    this.address = '',
    this.paymentInstructions = '',
    this.footerNote = '',
    this.brandColorHex = '#1E3A8A',
  });

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? email,
    String? gstin,
    String? upiId,
    String? address,
    String? paymentInstructions,
    String? footerNote,
    String? brandColorHex,
  }) => BusinessProfile(
        businessName: businessName ?? this.businessName,
        ownerName: ownerName ?? this.ownerName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        gstin: gstin ?? this.gstin,
        upiId: upiId ?? this.upiId,
        address: address ?? this.address,
        paymentInstructions: paymentInstructions ?? this.paymentInstructions,
        footerNote: footerNote ?? this.footerNote,
        brandColorHex: brandColorHex ?? this.brandColorHex,
      );

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'gstin': gstin,
        'upiId': upiId,
        'address': address,
        'paymentInstructions': paymentInstructions,
        'footerNote': footerNote,
        'brandColorHex': brandColorHex,
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        businessName: json['businessName'] ?? '',
        ownerName: json['ownerName'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        gstin: json['gstin'] ?? '',
        upiId: json['upiId'] ?? '',
        address: json['address'] ?? '',
        paymentInstructions: json['paymentInstructions'] ?? '',
        footerNote: json['footerNote'] ?? '',
        brandColorHex: json['brandColorHex'] ?? '#1E3A8A',
      );
}
