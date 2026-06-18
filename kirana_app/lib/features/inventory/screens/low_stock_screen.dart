import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/inventory_provider.dart';

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  void _showEditDialog(Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name'] as String? ?? '');
    final mrpCtrl = TextEditingController(text: '${product['mrp'] ?? 0}');
    final costCtrl = TextEditingController(text: '${product['costPrice'] ?? 0}');
    final stockCtrl = TextEditingController(text: '${product['stock'] ?? 0}');
    final lowStockCtrl = TextEditingController(text: '${product['lowStock'] ?? 5}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: mrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP (₹)')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (₹)')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: lowStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Alert')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final id = product['_id'] ?? product['id'];
                      if (id == null) return;
                      final updates = {
                        'name': nameCtrl.text.trim(),
                        'mrp': double.tryParse(mrpCtrl.text) ?? 0,
                        'costPrice': double.tryParse(costCtrl.text) ?? 0,
                        'stock': int.tryParse(stockCtrl.text) ?? 0,
                        'lowStock': int.tryParse(lowStockCtrl.text) ?? 5,
                      };
                      await ref.read(inventoryProvider.notifier).updateProduct(id.toString(), updates);
                      if (mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223960),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Low Stock Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (products) {
          final lowStockProducts = products.where((p) {
            final stock = (p['stock'] as num?)?.toInt() ?? 0;
            final lowStock = (p['lowStock'] as num?)?.toInt() ?? 5;
            return stock <= lowStock;
          }).toList()
            ..sort((a, b) {
              final aStock = (a['stock'] as num?)?.toInt() ?? 0;
              final bStock = (b['stock'] as num?)?.toInt() ?? 0;
              return aStock.compareTo(bStock);
            });

          if (lowStockProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 48, color: Color(0xFF22C55E)),
                  SizedBox(height: 16),
                  Text('All stocked up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('No products are running low', style: TextStyle(color: AppTheme.mutedForeground)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = lowStockProducts[index];
              final stock = (product['stock'] as num?)?.toInt() ?? 0;
              final lowStock = (product['lowStock'] as num?)?.toInt() ?? 5;
              final isOut = stock == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOut ? const Color(0xFFEF4444) : const Color(0xFFF97316),
                    width: 1.5,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] as String? ?? 'Unknown',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF223960)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product['category'] as String? ?? 'Others',
                                style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditDialog(product),
                          icon: const Icon(LucideIcons.pencil, size: 18, color: Color(0xFF0EA5E9)),
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOut ? 'OUT OF STOCK' : 'LOW STOCK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _infoChip('Stock', '$stock ${product['unit'] ?? 'pcs'}', isOut ? const Color(0xFFEF4444) : const Color(0xFFF97316)),
                        const SizedBox(width: 10),
                        _infoChip('Alert Level', '$lowStock', const Color(0xFF6B7280)),
                        const SizedBox(width: 10),
                        _infoChip('MRP', '₹${product['mrp'] ?? 0}', const Color(0xFF6B7280)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _infoChip('Cost', '₹${product['costPrice'] ?? 0}', const Color(0xFF6B7280)),
                        const SizedBox(width: 10),
                        _infoChip(
                          'Margin',
                          '₹${((product['mrp'] as num?)?.toDouble() ?? 0) - ((product['costPrice'] as num?)?.toDouble() ?? 0)}',
                          const Color(0xFF22C55E),
                        ),
                        if (product['barcode'] != null && (product['barcode'] as String).isNotEmpty) ...[
                          const SizedBox(width: 10),
                          _infoChip('Barcode', product['barcode'] as String, const Color(0xFF6B7280)),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
