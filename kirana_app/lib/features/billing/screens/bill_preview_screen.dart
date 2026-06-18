import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BillPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> bill;
  final String customerName;
  final String customerPhone;
  final String paymentMode;
  final String? shopUpiId;
  final String shopName;

  const BillPreviewScreen({
    super.key,
    required this.bill,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMode,
    this.shopUpiId,
    this.shopName = 'My Store',
  });

  @override
  Widget build(BuildContext context) {
    final items = bill['items'] as List<dynamic>? ?? [];
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final subtotal = (bill['subtotal'] as num?)?.toDouble() ?? total;
    final discount = (bill['discount'] as num?)?.toDouble() ?? 0;
    final createdAt = bill['createdAt'] as String? ?? '';
    final billId = bill['_id'] ?? bill['id'] ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        dateStr = createdAt;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bill',
          style: TextStyle(color: Color(0xFF223960), fontSize: 24, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF223960)),
        actions: [
          TextButton.icon(
            onPressed: () => _shareBill(context),
            icon: const Icon(LucideIcons.share, size: 16, color: Color(0xFF223960)),
            label: const Text('Share', style: TextStyle(color: Color(0xFF223960))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE5FFF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, color: Color(0xFF00C479), size: 48),
            ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 16),
            Text(
              paymentMode == 'CREDIT' ? 'Bill Created (Credit)' : 'Payment Successful',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF223960),
              ),
            ),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF00C479),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            // Bill Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shopName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223960), fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Bill #$billId', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const Divider(height: 24),

                  // Customer info
                  if (customerName.isNotEmpty || customerPhone.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 14, color: Color(0xFF8A8080)),
                        const SizedBox(width: 8),
                        Text(customerName.isNotEmpty ? customerName : 'Walk-in',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF223960))),
                        if (customerPhone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(customerPhone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Items
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF223960))),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] as String? ?? '',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF223960))),
                              Text(
                                'x${item['qty'] ?? item['quantity']} @ ₹${item['price']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${((item['total'] as num?) ?? ((item['price'] as num) * ((item['qty'] ?? item['quantity']) as num))).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF223960)),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                      Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF223960))),
                    ],
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: TextStyle(color: Colors.grey)),
                        Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF42018))),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223960))),
                      Text('₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223960))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Payment: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: paymentMode == 'CREDIT'
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentMode,
                          style: TextStyle(
                            color: paymentMode == 'CREDIT'
                                ? const Color(0xFFFF6900)
                                : const Color(0xFF00C479),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // App Branding
                  Center(
                    child: Text(
                      'Powered by Kirana App',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printBill(context),
                    icon: const Icon(LucideIcons.printer, size: 18),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF223960),
                      side: const BorderSide(color: Color(0xFF223960)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadBill(context),
                    icon: const Icon(LucideIcons.download, size: 18, color: Colors.white),
                    label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223960),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 16),

            // Back to Billing
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Back to Billing',
                  style: TextStyle(color: Color(0xFF8A8080), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  pw.Document _buildPdf() {
    final pdf = pw.Document();
    final items = bill['items'] as List<dynamic>? ?? [];
    final total = (bill['total'] as num?)?.toDouble() ?? 0;
    final createdAt = bill['createdAt'] as String? ?? '';
    final billId = bill['_id'] ?? bill['id'] ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        dateStr = createdAt;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Bill #$billId', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 10),
          if (customerName.isNotEmpty)
            pw.Text('Customer: $customerName (${customerPhone.isNotEmpty ? customerPhone : ""})'),
          pw.Divider(),
          pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...items.map((item) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text('${item['name']} x${item['qty'] ?? item['quantity']}')),
              pw.Text('₹${((item['total'] as num?) ?? ((item['price'] as num) * ((item['qty'] ?? item['quantity']) as num))).toStringAsFixed(2)}'),
            ],
          )),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('₹${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Payment: $paymentMode'),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Powered by Kirana App',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _printBill(BuildContext context) async {
    final pdf = _buildPdf();
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bill_${bill['_id'] ?? bill['id']}.pdf',
    );
  }

  Future<void> _downloadBill(BuildContext context) async {
    final pdf = _buildPdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Bill_${bill['_id'] ?? bill['id']}.pdf',
    );
  }

  Future<void> _shareBill(BuildContext context) async {
    final pdf = _buildPdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Bill_${bill['_id'] ?? bill['id']}.pdf',
    );
  }
}
