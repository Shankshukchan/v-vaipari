import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/bills_provider.dart';
import 'payment_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final List<Map<String, dynamic>> cart = [];
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)));
  double get total => subtotal;

  void removeItem(String id) {
    setState(() {
      cart.removeWhere((item) => item['id'] == id);
    });
  }

  void incrementQty(String id) {
    setState(() {
      final idx = cart.indexWhere((item) => item['id'] == id);
      if (idx != -1) {
        cart[idx]['quantity'] = (cart[idx]['quantity'] as int) + 1;
      }
    });
  }

  void decrementQty(String id) {
    setState(() {
      final idx = cart.indexWhere((item) => item['id'] == id);
      if (idx != -1) {
        final qty = cart[idx]['quantity'] as int;
        if (qty > 1) {
          cart[idx]['quantity'] = qty - 1;
        } else {
          cart.removeAt(idx);
        }
      }
    });
  }

  void addToCart(Map<String, dynamic> product) {
    final existingIdx = cart.indexWhere((item) => item['id'] == product['_id']);
    setState(() {
      if (existingIdx != -1) {
        cart[existingIdx]['quantity'] = (cart[existingIdx]['quantity'] as int) + 1;
      } else {
        cart.add({
          'id': product['_id'],
          'productId': product['_id'],
          'name': product['name'],
          'price': (product['mrp'] as num).toDouble(),
          'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0,
          'quantity': 1,
          'mrp': (product['mrp'] as num).toDouble(),
          'barcode': product['barcode'],
        });
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await openBarcodeScanner(context);
    if (barcode == null || barcode.isEmpty) return;

    final product = await ref.read(inventoryProvider.notifier).findByBarcode(barcode);
    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for barcode: $barcode')),
        );
      }
      return;
    }
    addToCart(product);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} added to cart')),
      );
    }
  }

  void _showProductPicker() {
    final asyncProducts = ref.read(inventoryProvider);
    final products = asyncProducts.value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = products.where((p) {
              final name = (p['name'] as String).toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(LucideIcons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        final stock = (p['stock'] as num?)?.toInt() ?? 0;
                        return ListTile(
                          title: Text(p['name'] as String),
                          subtitle: Text(
                            'MRP: ₹${p['mrp']} | Stock: $stock',
                            style: TextStyle(
                              color: stock == 0 ? Colors.red : Colors.grey,
                            ),
                          ),
                          trailing: stock > 0
                              ? const Icon(LucideIcons.plusCircle, color: Color(0xFF223960))
                              : const Text('Out', style: TextStyle(color: Colors.red)),
                          onTap: stock > 0
                              ? () {
                                  addToCart(p);
                                  Navigator.pop(ctx);
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _proceedToPayment() {
    if (cart.isEmpty) return;

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number is required')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          cart: List.from(cart),
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          subtotal: subtotal,
          total: total,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          cart.clear();
          _nameCtrl.clear();
          _phoneCtrl.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Bill's",
          style: TextStyle(
            color: Color(0xFF223960),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _showBillHistory,
              icon: const Text(
                'History',
                style: TextStyle(color: Color(0xFF8A8080), fontSize: 12),
              ),
              label: const Icon(
                LucideIcons.history,
                color: Color(0xFF8A8080),
                size: 16,
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _showProductPicker,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F6F6),
                      foregroundColor: const Color(0xFF223960),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Select Product', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(LucideIcons.scanLine, color: Color(0xFFFF6900)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF6F6F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  tooltip: 'Scan barcode',
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE5E7EB)),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.muted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.scanLine, size: 40, color: AppTheme.mutedForeground),
                        ),
                        const SizedBox(height: 16),
                        const Text('Scan a barcode or select a product',
                            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ...cart.map(
                        (item) => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF223960),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item['price']} each',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF223960)),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => decrementQty(item['id']),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F6F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(LucideIcons.minus, size: 14, color: Color(0xFF223960)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${item['quantity']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF223960),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => incrementQty(item['id']),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF223960),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '₹${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF223960),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => removeItem(item['id']),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF25955).withOpacity(0.24),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(LucideIcons.x, color: Color(0xFFF42018), size: 14),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: const Color(0xFF8A8080).withOpacity(0.3),
                              height: 24,
                            ),
                          ],
                        ).animate().fadeIn(),
                      ),

                      const SizedBox(height: 16),

                      // Customer Info
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
                              'Customer Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF223960),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Customer Name *',
                                prefixIcon: const Icon(LucideIcons.user, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Phone Number *',
                                prefixIcon: const Icon(LucideIcons.phone, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF223960), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Proceed Button
                      ElevatedButton(
                        onPressed: cart.isEmpty ? null : _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF223960), Color(0xFF0EA5E9)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Text(
                              'Proceed to Payment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showBillHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _BillHistoryScreen()),
    );
  }
}

// ─── Bill History Screen ─────────────────────────────────────────────────────

class _BillHistoryScreen extends ConsumerWidget {
  const _BillHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bill History',
          style: TextStyle(color: Color(0xFF223960), fontSize: 24, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF223960)),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(
              child: Text('No bills yet', style: TextStyle(color: Color(0xFF8A8080), fontSize: 16)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final billId = bill['_id'] ?? bill['id'] ?? '';
              final items = bill['items'] as List<dynamic>? ?? [];
              final total = (bill['total'] as num?)?.toDouble() ?? 0;
              final createdAt = bill['createdAt'] as String? ?? '';
              final customerName = bill['customerName'] as String?;
              final status = bill['status'] as String? ?? 'PAID';
              final billPaymentMode = bill['paymentMode'] as String? ?? 'CASH';

              String dateStr = '';
              if (createdAt.isNotEmpty) {
                try {
                  final dt = DateTime.parse(createdAt);
                  dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                } catch (_) {
                  dateStr = createdAt;
                }
              }

              return Dismissible(
                key: Key(billId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: const Color(0xFFD43500),
                  child: const Icon(LucideIcons.trash2, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Bill'),
                      content: const Text('Are you sure you want to delete this bill?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD43500),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref.read(billsProvider.notifier).deleteBill(billId);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: billPaymentMode == 'CREDIT'
                                      ? const Color(0xFFFFF3E0)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  billPaymentMode,
                                  style: TextStyle(
                                    color: billPaymentMode == 'CREDIT'
                                        ? const Color(0xFFFF6900)
                                        : const Color(0xFF00C479),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'PAID'
                                      ? const Color(0xFFE5FFF5)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'PAID' ? const Color(0xFF00C479) : const Color(0xFFFF6900),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (customerName != null && customerName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF223960),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']} x${item['quantity'] ?? item['qty']}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF223960)),
                              ),
                            ),
                            Text(
                              '₹${((item['total'] as num?) ?? ((item['price'] as num) * (item['quantity'] ?? item['qty'] as num))).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF223960)),
                            ),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223960))),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF223960),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
