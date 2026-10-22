


import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../customers/data/models/customer_model.dart';
import '../data/models/order_model.dart';

class InvoiceGenerator {
  InvoiceGenerator._();

  static final _currency = NumberFormat.currency(
    symbol: 'AED ',
    decimalDigits: 2,
    locale: 'en_AE',
  );

  static final _date = DateFormat('dd MMM yyyy');
  static final _time = DateFormat('hh:mm a');

  // ── Brand Colors ──────────────────────────────────────────
  static final PdfColor _navy = PdfColor.fromHex('#0F172A');
  static final PdfColor _blue = PdfColor.fromHex('#0EA5E9');
  static final PdfColor _textDark = PdfColor.fromHex('#1E293B');
  static final PdfColor _textGray = PdfColor.fromHex('#64748B');
  static final PdfColor _borderGray = PdfColor.fromHex('#E2E8F0');
  static final PdfColor _warningBg = PdfColor.fromHex('#FEF9C3');
  static final PdfColor _warningText = PdfColor.fromHex('#854D0E');
  static final PdfColor _successBg = PdfColor.fromHex('#DCFCE7');
  static final PdfColor _successText = PdfColor.fromHex('#166534');

  static Future<Uint8List> build({
    required OrderModel order,
    CustomerModel? customer,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    final doc = pw.Document();

    final name = businessName ?? 'DAR AL MURUZ';
    final phone = businessPhone ?? '0569691508';
    final address = businessAddress ?? 'Used Auto Parts & Accessories';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(name, address),
              pw.SizedBox(height: 24),
              _buildInfoSection(order, phone, name),
              pw.SizedBox(height: 24),
              _buildItemsTable(order),
              pw.SizedBox(height: 24),
              _buildBottomSection(order),
              pw.Spacer(),
              _buildFooter(name),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(String name, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name.toUpperCase(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                subtitle.toUpperCase(),
                style: pw.TextStyle(
                  color: _textGray,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              color: _blue,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoSection(
      OrderModel order, String phone, String businessName) {
    
    final categories = <String>{};
    for (final item in order.items) {
      if (item.categoryId.isNotEmpty) categories.add(item.categoryId);
    }
    final categoryDisplay = categories.isNotEmpty
        ? categories.join(', ')
        : 'Vehicle Spare Parts';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STORE & CONTACT INFORMATION',
                  style: pw.TextStyle(
                    color: _textGray,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 12),
                _infoRow('Shop Name:', businessName),
                pw.SizedBox(height: 6),
                _infoRow('Phone / WhatsApp:', phone),
                pw.SizedBox(height: 6),
                _infoRow('Specialization:', 'Mini Cooper Parts'),
                
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: _borderGray),
                pw.SizedBox(height: 12),

                pw.Text(
                  'BILL TO',
                  style: pw.TextStyle(
                    color: _textGray,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  order.customerName,
                  style: pw.TextStyle(
                    color: _textDark,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                // ★ Reads phone from the order now
                if (order.customerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    order.customerPhone,
                    style: pw.TextStyle(color: _textDark, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE DETAILS',
                  style: pw.TextStyle(
                    color: _textGray,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 12),
                _infoRow('Date:', _date.format(order.createdAt)),
                pw.SizedBox(height: 6),
                _infoRow('Time:', _time.format(order.createdAt)),
                pw.SizedBox(height: 6),
                _infoRowWithBadge(
                  'Payment Method:',
                  'Cash Paid',
                  'PAID',
                ),
                pw.SizedBox(height: 6),
                _infoRow('Category:', categoryDisplay),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoRowWithBadge(
      String label, String value, String badge) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _textDark,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: pw.BoxDecoration(
            color: _successBg,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(
            badge,
            style: pw.TextStyle(
              color: _successText,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(OrderModel order) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: pw.BoxDecoration(color: _navy),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  '#',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'ITEM DESCRIPTION',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(
                width: 50,
                child: pw.Text(
                  'QTY',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  'UNIT PRICE',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  'TOTAL',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...order.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _borderGray),
                left: pw.BorderSide(color: _borderGray),
                right: pw.BorderSide(color: _borderGray),
              ),
            ),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 40,
                  child: pw.Text('${index + 1}', style: pw.TextStyle(color: _textDark, fontSize: 10)),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.productName,
                        style: pw.TextStyle(color: _navy, fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Genuine used Mini Cooper part - Inspected',
                        style: pw.TextStyle(color: _textGray, fontSize: 9),
                      ),
                      if (item.hasDiscount) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Discount applied: ${item.discountType == 'percent' ? '${item.discountValue}%' : _currency.format(item.discountValue)} off/unit',
                          style: pw.TextStyle(color: _warningText, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ]
                    ],
                  ),
                ),
                pw.SizedBox(
                  width: 50,
                  child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: _textDark, fontSize: 11)),
                ),
                pw.SizedBox(
                  width: 80,
                  // ★ Changed to Selling Price
                  child: pw.Text(_currency.format(item.sellingPrice), textAlign: pw.TextAlign.right, style: pw.TextStyle(color: _textDark, fontSize: 11)),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(_currency.format(item.lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(color: _textDark, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildBottomSection(OrderModel order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _warningBg,
              border: pw.Border(left: pw.BorderSide(color: _warningText, width: 3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Warranty Notice:',
                  style: pw.TextStyle(color: _warningText, fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'This item comes with a 3 DAYS WARRANTY from the date of purchase. Please retain this invoice for any warranty claims.',
                  style: pw.TextStyle(color: _warningText, fontSize: 9, lineSpacing: 2),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _totalRow('Subtotal:', _currency.format(order.subtotal)),
                pw.SizedBox(height: 8),
                _totalRow('Discount:', _currency.format(order.discountAmount)),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: _borderGray),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Paid:', style: pw.TextStyle(color: _navy, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_currency.format(order.total), style: pw.TextStyle(color: _blue, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: _textGray, fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(color: _textDark, fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildFooter(String businessName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 1, color: _borderGray),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('* Used parts are tested prior to sale.', style: pw.TextStyle(color: _textGray, fontSize: 8)),
                  pw.SizedBox(height: 2),
                  pw.Text('* Warranty covers functional defects within 3 days.', style: pw.TextStyle(color: _textGray, fontSize: 8)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 120,
                  child: pw.Text(
                    'AUTHORIZED SIGNATURE',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(color: _textGray, fontSize: 8, letterSpacing: 1),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 120,
                  child: pw.Text(
                    'Arfath',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(color: _navy, fontSize: 18, fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(width: 120, height: 1, color: _borderGray),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Center(
          child: pw.Text(
            'Thank you for doing business with $businessName!',
            style: pw.TextStyle(color: _textGray, fontSize: 9),
          ),
        ),
      ],
    );
  }
}