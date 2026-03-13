// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BillBeeApp());
}

class BillBeeApp extends StatelessWidget {
  const BillBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillBee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4B400),
          primary: const Color(0xFFF4B400),
          secondary: const Color(0xFF1A73E8),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'NotoSans',
        useMaterial3: true,
      ),
      home: const BillBeeHome(),
    );
  }
}

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
      final seed = _seedData();
      await save(seed.customers, seed.documents, seed.estimateCounter, seed.invoiceCounter);
      return seed;
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

  static BillBeeSeedData _seedData() {
    final customers = [
      const Customer(name: 'Ravi Electricals', phone: '+91 98765 43210', businessType: 'Service'),
      const Customer(name: 'Ananya Design Studio', phone: '+91 91234 56789', businessType: 'Freelancer'),
      const Customer(name: 'Sri Sai Traders', phone: '+91 99887 76655', businessType: 'Retail'),
    ];
    final documents = [
      DocItem(
        id: 'EST-1001',
        type: 'Estimate',
        customer: customers[0],
        status: 'Pending',
        date: DateTime.now().subtract(const Duration(days: 1)),
        items: const [
          LineItem(name: 'Electrical Repair Visit', quantity: 1, price: 1200),
          LineItem(name: 'Wiring Material', quantity: 2, price: 350),
        ],
      ),
      DocItem(
        id: 'INV-2034',
        type: 'Invoice',
        customer: customers[1],
        status: 'Paid',
        date: DateTime.now().subtract(const Duration(days: 2)),
        items: const [
          LineItem(name: 'Logo Design', quantity: 1, price: 5000),
          LineItem(name: 'Social Media Banner Pack', quantity: 1, price: 2500),
        ],
      ),
    ];
    return BillBeeSeedData(
      customers: customers,
      documents: documents,
      estimateCounter: 1002,
      invoiceCounter: 2036,
    );
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

class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
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
        gstin: json['gstin'] ?? '',
        upiId: json['upiId'] ?? '',
        address: json['address'] ?? '',
        paymentInstructions: json['paymentInstructions'] ?? '',
        footerNote: json['footerNote'] ?? '',
        brandColorHex: json['brandColorHex'] ?? '#1E3A8A',
      );
}


String buildShareText(DocItem document) {
  final buffer = StringBuffer();
  buffer.writeln('${document.type}: ${document.id}');
  buffer.writeln('Customer: ${document.customer.name}');
  buffer.writeln('Phone: ${document.customer.phone}');
  buffer.writeln('Status: ${document.status}');
  buffer.writeln('Date: ${document.date.toLocal()}'.split('.').first);
  buffer.writeln('');
  buffer.writeln('Items:');
  for (final item in document.items) {
    buffer.writeln('- ${item.name} | ${item.quantity} × ₹${item.price.toStringAsFixed(0)} = ₹${item.total.toStringAsFixed(0)}');
  }
  buffer.writeln('');
  buffer.writeln(document.taxEnabled ? 'GST (${document.taxPercent.toStringAsFixed(1)}%): ₹${document.gst.toStringAsFixed(0)}' : 'GST: Disabled');
  buffer.writeln('Total: ₹${document.total.toStringAsFixed(0)}');
  buffer.writeln('');
  buffer.writeln('Sent from BillBee');
  return buffer.toString();
}

Future<Uint8List> generatePdfBytes(DocItem document, BusinessProfile profile) async {
  final pdf = pw.Document();
  final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final baseFont = pw.Font.ttf(fontData);
  final primary = PdfColor.fromHex(profile.brandColorHex.isNotEmpty ? profile.brandColorHex : '#1E3A8A');
  final ink = PdfColor.fromHex('#0F172A');
  final muted = PdfColor.fromHex('#6B7280');
  final border = PdfColor.fromHex('#E5E7EB');
  final soft = PdfColor.fromHex('#F9FAFB');

  String money(num value) => '₹${value.toStringAsFixed(0)}';

  pw.Widget metaChip(String label, String value) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: soft,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: border),
        ),
        child: pw.Row(
          children: [
            pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, color: muted)),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9.5, color: ink, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      );

  pw.Widget totalRow(String label, String value, {bool grand = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: grand ? 11 : 10, color: grand ? ink : muted, fontWeight: grand ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value, style: pw.TextStyle(fontSize: grand ? 14 : 10, color: ink, fontWeight: grand ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        theme: pw.ThemeData.withFont(base: baseFont, bold: baseFont, italic: baseFont, boldItalic: baseFont),
      ),
      build: (_) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.businessName.isNotEmpty ? profile.businessName : 'BillBee Business',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primary),
                ),
                pw.SizedBox(height: 4),
                if (profile.ownerName.isNotEmpty)
                  pw.Text(profile.ownerName, style: pw.TextStyle(fontSize: 12, color: ink)),
                pw.SizedBox(height: 12),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(document.type.toUpperCase(), style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: primary)),
                pw.Transform.translate(offset: const PdfPoint(0, -20), child: pw.Text(document.id, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: ink))),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DETAILS', style: pw.TextStyle(fontSize: 10, color: muted, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  if (profile.phone.isNotEmpty) metaChip('Phone', profile.phone),
                  if (profile.address.isNotEmpty) metaChip('Address', profile.address),
                  if (profile.gstin.isNotEmpty) metaChip('GSTIN', profile.gstin),
                  if (profile.upiId.isNotEmpty) metaChip('UPI ID', profile.upiId),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, color: muted, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(document.customer.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: ink)),
                  pw.SizedBox(height: 4),
                  pw.Text(document.customer.phone, style: pw.TextStyle(fontSize: 11, color: ink)),
                  pw.Text(document.customer.businessType, style: pw.TextStyle(fontSize: 11, color: muted)),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(color: soft, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                    child: pw.Text(document.status, style: pw.TextStyle(fontSize: 10, color: primary, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: border, width: 0.5),
            bottom: pw.BorderSide(color: ink, width: 1),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: ink, width: 1.5))),
              children: ['Description', 'Qty', 'Price', 'Total']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 10),
                        child: pw.Text(h, style: pw.TextStyle(fontSize: 10, color: ink, fontWeight: pw.FontWeight.bold)),
                      ))
                  .toList(),
            ),
            ...document.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12), child: pw.Text(item.name, style: pw.TextStyle(fontSize: 11, color: ink))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12), child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 11, color: ink))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12), child: pw.Text(money(item.price), style: pw.TextStyle(fontSize: 11, color: ink))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12), child: pw.Text(money(item.total), style: pw.TextStyle(fontSize: 11, color: ink, fontWeight: pw.FontWeight.bold))),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PAYMENT INFO', style: pw.TextStyle(fontSize: 9, color: muted, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    profile.paymentInstructions.isNotEmpty
                        ? profile.paymentInstructions
                        : (profile.upiId.isNotEmpty ? 'UPI: ${profile.upiId}' : 'Thank you for your business.'),
                    style: pw.TextStyle(fontSize: 10, color: ink, lineSpacing: 1.5),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                children: [
                  totalRow('Subtotal', money(document.subtotal)),
                  if (document.taxEnabled) totalRow('GST (${document.taxPercent.toStringAsFixed(1)}%)', money(document.gst)),
                  pw.Divider(color: border, thickness: 0.5),
                  pw.SizedBox(height: 4),
                  totalRow('Total Amount', money(document.total), grand: true),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 50),
        pw.Divider(color: border, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(profile.footerNote.isNotEmpty ? profile.footerNote : 'Thank you for choosing ${profile.businessName}!', style: pw.TextStyle(fontSize: 9, color: muted)),
            pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 9, color: muted)),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

Future<File> generatePdfFile(DocItem document, BusinessProfile profile) async {
  final bytes = await generatePdfBytes(document, profile);
  final dir = await getTemporaryDirectory();
  final safeId = document.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final file = File('${dir.path}/$safeId.pdf');
  await file.writeAsBytes(bytes);
  return file;
}

class BillBeeHome extends StatefulWidget {
  const BillBeeHome({super.key});

  @override
  State<BillBeeHome> createState() => _BillBeeHomeState();
}

class _BillBeeHomeState extends State<BillBeeHome> {
  int _index = 0;
  bool _loading = true;
  List<Customer> _customers = [];
  List<DocItem> _documents = [];
  int _estimateCounter = 1002;
  int _invoiceCounter = 2036;
  BusinessProfile _businessProfile = const BusinessProfile();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await BillBeeStore.load();
    final profile = await BillBeeStore.loadBusinessProfile();
    setState(() {
      _customers = data.customers;
      _documents = data.documents;
      _estimateCounter = data.estimateCounter;
      _invoiceCounter = data.invoiceCounter;
      _businessProfile = profile;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await BillBeeStore.save(_customers, _documents, _estimateCounter, _invoiceCounter);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _HomeTab(documents: _documents, onQuickCreate: _showCreateSheet),
      _DocumentsTab(
        documents: _documents,
        businessProfile: _businessProfile,
        onConvertEstimate: _convertEstimateToInvoice,
        onStatusChange: _changeStatus,
        onOpenDetail: _openDetail,
      ),
      _CustomersTab(customers: _customers, onAddCustomer: _openAddCustomer, onEditCustomer: _openEditCustomer),
      _SettingsTab(profile: _businessProfile, onSave: _saveBusinessProfile),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4B400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('B', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black))),
            ),
            const SizedBox(width: 10),
            const Text('BillBee', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: pages[_index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create new', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateDocument('Estimate');
                },
                child: const _CreateActionTile(
                  icon: Icons.request_quote,
                  title: 'New Estimate',
                  subtitle: 'Send a quick quote on WhatsApp',
                  color: Color(0xFFF4B400),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateDocument('Invoice');
                },
                child: const _CreateActionTile(
                  icon: Icons.receipt_long,
                  title: 'New Invoice',
                  subtitle: 'Create and share a professional invoice',
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDocument(String type) async {
    final created = await Navigator.push<DocItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDocumentPage(
          type: type,
          customers: _customers,
          nextId: type == 'Estimate' ? 'EST-$_estimateCounter' : 'INV-$_invoiceCounter',
        ),
      ),
    );

    if (created != null) {
      setState(() {
        _documents.insert(0, created);
        if (type == 'Estimate') {
          _estimateCounter++;
        } else {
          _invoiceCounter++;
        }
        _index = 1;
      });
      await _persist();
    }
  }

  Future<void> _convertEstimateToInvoice(DocItem estimate) async {
    final invoice = DocItem(
      id: 'INV-${_invoiceCounter++}',
      type: 'Invoice',
      customer: estimate.customer,
      status: 'Unpaid',
      date: DateTime.now(),
      items: estimate.items,
    );
    setState(() => _documents.insert(0, invoice));
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${estimate.id} converted to ${invoice.id}')));
    }
  }

  Future<void> _changeStatus(DocItem doc, String newStatus) async {
    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx == -1) return;
    setState(() => _documents[idx] = doc.copyWith(status: newStatus));
    await _persist();
  }

  Future<void> _openDetail(DocItem doc) async {
    final result = await Navigator.push<DocumentActionResult>(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailPage(args: DocumentDetailArgs(document: doc, customers: _customers, businessProfile: _businessProfile))),
    );
    if (result == null) return;

    final idx = _documents.indexWhere((d) => d.id == doc.id);
    if (idx == -1) return;

    if (result.delete) {
      setState(() => _documents.removeAt(idx));
      await _persist();
      return;
    }

    if (result.document != null) {
      setState(() => _documents[idx] = result.document!);
      await _persist();
    }
  }

  Future<void> _openAddCustomer() async {
    final created = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCustomerPage()),
    );
    if (created != null) {
      setState(() {
        _customers = [created, ..._customers];
      });
      await _persist();
    }
  }

  Future<void> _openEditCustomer(Customer customer) async {
    final updated = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => CreateCustomerPage(customer: customer)),
    );
    if (updated != null) {
      final customerIdx = _customers.indexWhere((c) => c.name == customer.name && c.phone == customer.phone);
      if (customerIdx != -1) {
        setState(() {
          _customers[customerIdx] = updated;
          _documents = _documents
              .map((d) => d.customer.name == customer.name && d.customer.phone == customer.phone ? d.copyWith(customer: updated) : d)
              .toList();
        });
        await _persist();
      }
    }
  }

  Future<void> _saveBusinessProfile(BusinessProfile profile) async {
    setState(() => _businessProfile = profile);
    await BillBeeStore.saveBusinessProfile(profile);
  }
}

class _HomeTab extends StatelessWidget {
  final List<DocItem> documents;
  final VoidCallback onQuickCreate;
  const _HomeTab({required this.documents, required this.onQuickCreate});

  @override
  Widget build(BuildContext context) {
    final unpaid = documents.where((e) => e.status == 'Unpaid').fold<double>(0, (s, d) => s + d.total);
    final paid = documents.where((e) => e.status == 'Paid').fold<double>(0, (s, d) => s + d.total);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF5AA0FF)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Built for fast billing', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('Create estimates and invoices in under a minute.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onQuickCreate,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A73E8)),
              child: const Text('Quick create'),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _MetricCard(title: 'Unpaid', value: '₹${unpaid.toStringAsFixed(0)}', color: const Color(0xFFEF4444), icon: Icons.pending_actions),
            _MetricCard(title: 'Paid', value: '₹${paid.toStringAsFixed(0)}', color: const Color(0xFF16A34A), icon: Icons.verified),
            _MetricCard(title: 'Invoices', value: '${documents.where((e) => e.type == 'Invoice').length}', color: const Color(0xFF1A73E8), icon: Icons.receipt_long),
            _MetricCard(title: 'Estimates', value: '${documents.where((e) => e.type == 'Estimate').length}', color: const Color(0xFFF59E0B), icon: Icons.request_quote),
          ],
        ),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final List<DocItem> documents;
  final BusinessProfile businessProfile;
  final Future<void> Function(DocItem) onConvertEstimate;
  final Future<void> Function(DocItem, String) onStatusChange;
  final Future<void> Function(DocItem) onOpenDetail;
  const _DocumentsTab({required this.documents, required this.businessProfile, required this.onConvertEstimate, required this.onStatusChange, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...documents.map((doc) => _DocumentCard(
          document: doc,
          onOpen: () => onOpenDetail(doc),
          onPdfPreview: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerPage(document: doc, profile: businessProfile)));
          },
          onShare: () async {
            final bytes = await generatePdfBytes(doc, businessProfile);
            await Printing.sharePdf(bytes: bytes, filename: '${doc.id}.pdf');
          },
          onConvertEstimate: doc.type == 'Estimate' ? () => onConvertEstimate(doc) : null,
          onStatusChange: (status) => onStatusChange(doc, status),
        )),
      ],
    );
  }
}

class _CustomersTab extends StatelessWidget {
  final List<Customer> customers;
  final Future<void> Function() onAddCustomer;
  final Future<void> Function(Customer) onEditCustomer;
  const _CustomersTab({required this.customers, required this.onAddCustomer, required this.onEditCustomer});

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

class _SettingsTab extends StatefulWidget {
  final BusinessProfile profile;
  final Future<void> Function(BusinessProfile) onSave;
  const _SettingsTab({required this.profile, required this.onSave});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _gstinController;
  late final TextEditingController _upiController;
  late final TextEditingController _addressController;
  late final TextEditingController _paymentInstructionsController;
  late final TextEditingController _footerNoteController;
  late final TextEditingController _brandColorController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.profile.businessName);
    _ownerNameController = TextEditingController(text: widget.profile.ownerName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _gstinController = TextEditingController(text: widget.profile.gstin);
    _upiController = TextEditingController(text: widget.profile.upiId);
    _addressController = TextEditingController(text: widget.profile.address);
    _paymentInstructionsController = TextEditingController(text: widget.profile.paymentInstructions);
    _footerNoteController = TextEditingController(text: widget.profile.footerNote);
    _brandColorController = TextEditingController(text: widget.profile.brandColorHex);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _upiController.dispose();
    _addressController.dispose();
    _paymentInstructionsController.dispose();
    _footerNoteController.dispose();
    _brandColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(int.parse(profile.brandColorHex.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                  child: Text(
                    (profile.businessName.isNotEmpty ? profile.businessName : 'B').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(int.parse(profile.brandColorHex.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.businessName.isNotEmpty ? profile.businessName : 'Set Business Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                if (profile.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.ownerName, style: const TextStyle(color: Colors.black54, fontSize: 16)),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _ProfileInfoTile(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone.isNotEmpty ? profile.phone : 'Not set'),
                _ProfileInfoTile(icon: Icons.branding_watermark_outlined, label: 'GSTIN', value: profile.gstin.isNotEmpty ? profile.gstin : 'Not set'),
                _ProfileInfoTile(icon: Icons.account_balance_wallet_outlined, label: 'UPI ID', value: profile.upiId.isNotEmpty ? profile.upiId : 'Not set'),
                _ProfileInfoTile(icon: Icons.location_on_outlined, label: 'Address', value: profile.address.isNotEmpty ? profile.address : 'Not set'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showEditSheet,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Business Info'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Business', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _ownerNameController, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _gstinController, decoration: const InputDecoration(labelText: 'GSTIN', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _upiController, decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _addressController, maxLines: 3, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _paymentInstructionsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Payment Instructions', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _footerNoteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Footer Note', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _brandColorController, decoration: const InputDecoration(labelText: 'Brand Color Hex', hintText: '#1A73E8', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _save();
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final hex = _brandColorController.text.trim();
    final validHex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(hex) ? hex : '#1A73E8';
    widget.onSave(
      BusinessProfile(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gstin: _gstinController.text.trim(),
        upiId: _upiController.text.trim(),
        address: _addressController.text.trim(),
        paymentInstructions: _paymentInstructionsController.text.trim(),
        footerNote: _footerNoteController.text.trim(),
        brandColorHex: validHex,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated')));
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileInfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black45),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

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
        _SectionCard(
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
        _SectionCard(
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
        _SectionCard(
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
        _SectionCard(
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
        _SectionCard(
          title: 'Summary',
          child: Column(children: [
            _SummaryRow(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
            _SummaryRow(label: _taxEnabled ? 'GST (${taxPercent.toStringAsFixed(1)}%)' : 'GST (Disabled)', value: '₹${gst.toStringAsFixed(0)}'),
            const Divider(),
            _SummaryRow(label: 'Total', value: '₹${total.toStringAsFixed(0)}', bold: true),
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
        taxPercent: double.tryParse(_taxPercentController.text.trim()) ?? 0,
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Customer details',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Customer name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Business type', border: OutlineInputBorder()),
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
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final type = _typeController.text.trim();
    if (name.isEmpty || phone.isEmpty || type.isEmpty) return;
    Navigator.pop(context, Customer(name: name, phone: phone, businessType: type));
  }
}

class DocumentDetailPage extends StatefulWidget {
  final DocumentDetailArgs args;
  const DocumentDetailPage({super.key, required this.args});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late String _status;

  DocItem get _document => widget.args.document;

  @override
  void initState() {
    super.initState();
    _status = _document.status;
  }

  @override
  Widget build(BuildContext context) {
    final currentDoc = _document.copyWith(status: _status);
    return Scaffold(
      appBar: AppBar(
        title: Text(_document.id),
        actions: [
          IconButton(
            tooltip: 'Delete document',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete document?'),
                  content: Text('This will remove ${_document.id} from BillBee.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                navigator.pop(const DocumentActionResult(delete: true));
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '${_document.type} overview',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customer: ${_document.customer.name}'),
              Text('Phone: ${_document.customer.phone}'),
              Text('Date: ${_document.date.toLocal()}'.split('.').first),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: (_document.type == 'Invoice'
                        ? ['Unpaid', 'Paid', 'Partial']
                        : ['Pending', 'Approved', 'Rejected'])
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Items',
            child: Column(children: _document.items.map((i) => ListTile(contentPadding: EdgeInsets.zero, title: Text(i.name), subtitle: Text('${i.quantity} × ₹${i.price.toStringAsFixed(0)}'), trailing: Text('₹${i.total.toStringAsFixed(0)}'))).toList()),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Totals',
            child: Column(children: [
              _SummaryRow(label: 'Subtotal', value: '₹${_document.subtotal.toStringAsFixed(0)}'),
              _SummaryRow(label: _document.taxEnabled ? 'GST (${_document.taxPercent.toStringAsFixed(1)}%)' : 'GST (Disabled)', value: '₹${_document.gst.toStringAsFixed(0)}'),
              const Divider(),
              _SummaryRow(label: 'Total', value: '₹${_document.total.toStringAsFixed(0)}', bold: true),
            ]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final edited = await Navigator.push<DocItem>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateDocumentPage(
                        type: _document.type,
                        customers: widget.args.customers,
                        nextId: _document.id,
                        initialDocument: currentDoc,
                      ),
                    ),
                  );
                  if (edited != null) {
                    navigator.pop(DocumentActionResult(document: edited));
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit document'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerPage(document: currentDoc, profile: widget.args.businessProfile)));
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Preview PDF'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final bytes = await generatePdfBytes(currentDoc, widget.args.businessProfile);
                  await Printing.sharePdf(bytes: bytes, filename: '${currentDoc.id}.pdf');
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share now'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, DocumentActionResult(document: currentDoc)),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final DocItem document;
  final BusinessProfile profile;
  const PdfViewerPage({super.key, required this.document, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.id)),
      body: PdfPreview(
        build: (format) => generatePdfBytes(document, profile),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 12), child]),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _MetricCard({required this.title, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.black54))]),
      );
}

class _DocumentCard extends StatelessWidget {
  final DocItem document;
  final VoidCallback? onConvertEstimate;
  final ValueChanged<String>? onStatusChange;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onPdfPreview;
  const _DocumentCard({required this.document, this.onConvertEstimate, this.onStatusChange, this.onOpen, this.onShare, this.onPdfPreview});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (document.status) {
      'Paid' => const Color(0xFF16A34A),
      'Unpaid' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(document.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)), child: Text(document.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 8),
            Text('${document.type} • ${document.customer.name}'),
            const SizedBox(height: 8),
            Text('₹${document.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: onPdfPreview,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
              FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
              if (onConvertEstimate != null) FilledButton.tonalIcon(onPressed: onConvertEstimate, icon: const Icon(Icons.swap_horiz), label: const Text('To Invoice')),
              if (onStatusChange != null && document.type == 'Invoice')
                PopupMenuButton<String>(
                  onSelected: onStatusChange,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Unpaid', child: Text('Mark Unpaid')),
                    PopupMenuItem(value: 'Paid', child: Text('Mark Paid')),
                    PopupMenuItem(value: 'Partial', child: Text('Mark Partial')),
                  ],
                  child: const Chip(label: Text('Status')),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CreateActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _CreateActionTile({required this.icon, required this.title, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black12)),
        child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])), const Icon(Icons.chevron_right)]),
      );
}
