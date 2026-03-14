import '../models/customer.dart';
import '../models/doc_item.dart';
import '../models/business_profile.dart';

class DocumentActionResult {
  final DocItem? document;
  final bool delete;
  const DocumentActionResult({this.document, this.delete = false});
}

class DocumentDetailArgs {
  final DocItem document;
  final List<Customer> customers;
  final BusinessProfile businessProfile;
  const DocumentDetailArgs({required this.document, required this.customers, required this.businessProfile});
}
