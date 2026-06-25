import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../khata/providers/khata_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/bills_provider.dart';
import 'bill_preview_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> cart;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double total;

  const PaymentScreen({
    super.key,
    required this.cart,
    required this.customerName,
    required this.customerPhone,
    required this.subtotal,
    required this.total,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String paymentMode = 'CASH';
  String? shopUpiId;
  String _shopName = 'My Store';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/auth/me');
      if (response.data['success'] == true) {
        final shop = response.data['data']['shop'];
        if (shop != null) {
          setState(() {
            shopUpiId = shop['upiId'] as String?;
            _shopName = shop['name'] as String? ?? 'My Store';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _promptForUpiId() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter UPI ID'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. shopname@upi',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6900),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Save to backend
      final dio = ref.read(dioProvider);
      try {
        await dio.patch('/auth/me', data: {'upiId': result});
        setState(() {
          shopUpiId = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI ID saved')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save UPI ID: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final dio = ref.read(dioProvider);

      // For credit payment, find existing customer by phone
      String? customerId;
      if (paymentMode == 'CREDIT' && widget.customerPhone.isNotEmpty) {
        final customers = ref.read(khataProvider).value ?? [];
        for (final c in customers) {
          if (c['phone'] == widget.customerPhone) {
            customerId = c['_id'] as String?;
            break;
          }
        }
      }

      final response = await dio.post('/bills', data: {
        'items': widget.cart.map((item) => {
          'productId': item['productId'] ?? item['id'],
          'qty': item['quantity'],
        }).toList(),
        'discount': 0,
        'paymentMode': paymentMode,
        'customerName': widget.customerName,
        'customerPhone': widget.customerPhone,
        if (customerId != null) 'customerId': customerId,
      });

      if (response.data['success'] == true) {
        final serverBill = response.data['data'] as Map<String, dynamic>;

        // Refresh bills list and inventory stock
        ref.read(billsProvider.notifier).fetchBills();
        ref.read(inventoryProvider.notifier).fetchProducts();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BillPreviewScreen(
                bill: serverBill,
                customerName: widget.customerName,
                customerPhone: widget.customerPhone,
                paymentMode: paymentMode,
                shopUpiId: shopUpiId,
                shopName: _shopName,
              ),
            ),
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create bill');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Color(0xFF223960),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF223960)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223960), fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...widget.cart.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF223960)),
                          ),
                        ),
                        Text(
                          '₹${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF223960)),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223960))),
                      Text('₹${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223960))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Mode Selection
            const Text(
              'Select Payment Mode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF223960),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildPaymentOption('CASH', LucideIcons.banknote, 'Pay with cash'),
                const SizedBox(width: 8),
                _buildPaymentOption('UPI', LucideIcons.smartphone, 'Scan QR code'),
                const SizedBox(width: 8),
                _buildPaymentOption('CREDIT', LucideIcons.clock, 'Pay later'),
              ],
            ),

            const SizedBox(height: 24),

            // UPI QR Code Section
            if (paymentMode == 'UPI') ...[
              if (shopUpiId == null || shopUpiId!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Color(0xFFE6A817), size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        'UPI ID not set',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223960)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Please set your UPI ID to generate QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _promptForUpiId,
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Set UPI ID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6900),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Container(
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
                      children: [
                        const Text(
                          'Scan to Pay',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF223960),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C479),
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        QrImageView(
                          data: _generateUpiString(),
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          shopUpiId!,
                          style: const TextStyle(
                            color: Color(0xFF8A8080),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                  ),
                ),
            ],

            if (paymentMode == 'CREDIT') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6900)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Color(0xFFFF6900), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.customerName.isNotEmpty
                            ? 'Amount will be added to ${widget.customerName}\'s balance in Khata.'
                            : 'Please provide customer name and phone for credit payment.',
                        style: const TextStyle(color: Color(0xFF223960), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isProcessing || (paymentMode == 'UPI' && (shopUpiId == null || shopUpiId!.isEmpty)))
                    ? null
                    : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isProcessing
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [const Color(0xFF223960), const Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            paymentMode == 'CASH'
                                ? 'Confirm Cash Payment'
                                : paymentMode == 'UPI'
                                    ? 'Confirm UPI Payment'
                                    : 'Confirm Credit Payment',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String mode, IconData icon, String subtitle) {
    final isSelected = paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => paymentMode = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF223960) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF223960) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : const Color(0xFF223960),
              ),
              const SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF223960),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateUpiString() {
    final amount = widget.total.toStringAsFixed(2);
    final name = Uri.encodeComponent('Shop');
    return 'upi://pay?pa=$shopUpiId&pn=$name&am=$amount&cu=INR';
  }
}
