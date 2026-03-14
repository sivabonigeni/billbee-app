import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/doc_item.dart';
import '../models/line_item.dart';
import '../models/business_profile.dart';

class BillBeeStore {
  static const _customersKey = 'billbee_customers_v1';
  static const _documentsKey = 'billbee_documents_v1';
  static const _estimateCounterKey = 'billbee_estimate_counter_v1';
  static const _invoiceCounterKey = 'billbee_invoice_counter_v1';
  static const _businessProfileKey = 'billbee_business_profile_v1';

  static Future<BillBeeSeedData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final customerRaw = prefs.getString(_customersKey);
    final documentRaw = prefs.getString(_documentsKey);

    if (customerRaw == null || documentRaw == null) {
      return BillBeeSeedData(
        customers: [],
        documents: [],
        estimateCounter: 1001,
        invoiceCounter: 2001,
      );
    }

    final customers = (jsonDecode(customerRaw) as List)
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final documents = (jsonDecode(documentRaw) as List)
        .map((e) => DocItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return BillBeeSeedData(
      customers: customers,
      documents: documents,
      estimateCounter: prefs.getInt(_estimateCounterKey) ?? 1002,
      invoiceCounter: prefs.getInt(_invoiceCounterKey) ?? 2036,
    );
  }

  static Future<void> save(
    List<Customer> customers,
    List<DocItem> documents,
    int estimateCounter,
    int invoiceCounter,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customersKey, jsonEncode(customers.map((e) => e.toJson()).toList()));
    await prefs.setString(_documentsKey, jsonEncode(documents.map((e) => e.toJson()).toList()));
    await prefs.setInt(_estimateCounterKey, estimateCounter);
    await prefs.setInt(_invoiceCounterKey, invoiceCounter);
  }

  static Future<BusinessProfile> loadBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_businessProfileKey);
    if (raw == null) return const BusinessProfile();
    return BusinessProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  static Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessProfileKey, jsonEncode(profile.toJson()));
  }


}

class BillBeeSeedData {
  final List<Customer> customers;
  final List<DocItem> documents;
  final int estimateCounter;
  final int invoiceCounter;

  BillBeeSeedData({
    required this.customers,
    required this.documents,
    required this.estimateCounter,
    required this.invoiceCounter,
  });
}
