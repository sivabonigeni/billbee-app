import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/doc_item.dart';
import '../models/business_profile.dart';

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
