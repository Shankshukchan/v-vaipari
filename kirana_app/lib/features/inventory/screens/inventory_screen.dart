import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String searchQuery = '';
  bool showAddProduct = false;

  String getStockStatus(int stock, int alert) {
    if (stock == 0) return 'out';
    if (stock <= alert) return 'low';
    return 'good';
  }

  Color getStockColor(String status) {
    if (status == 'out') return const Color(0xFFEF4444); // red-500
    if (status == 'low') return const Color(0xFFF97316); // orange-500
    return const Color(0xFF22C55E); // green-500
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: mrpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'MRP / Selling Price'),
              ),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost Price'),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Initial Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && mrpCtrl.text.isNotEmpty) {
                ref.read(inventoryProvider.notifier).addProduct({
                  'name': nameCtrl.text,
                  'mrp': double.tryParse(mrpCtrl.text) ?? 0,
                  'costPrice': double.tryParse(costCtrl.text) ?? 0,
                  'stock': double.tryParse(stockCtrl.text) ?? 0,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory',
              style: TextStyle(
                color: Color(0xFF223960),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            asyncProducts.maybeWhen(
              data: (products) => Text(
                '${products.length} products',
                style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12),
              ),
              orElse: () => const Text(
                'Loading...',
                style: TextStyle(color: Color(0xFF8A8080), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () => ref.read(inventoryProvider.notifier).fetchProducts(),
              icon: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF8A8080), fontSize: 12),
              ),
              label: const Icon(
                LucideIcons.refresh_cw,
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
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          final filteredProducts = products
              .where(
                (p) => (p['name'] as String).toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
          final totalItems = products.length;
          final totalStockValue = products.fold<double>(
            0,
            (sum, p) => sum + ((p['stock'] as num).toDouble() * (p['mrp'] as num).toDouble()),
          );
          final totalProfit = products.fold<double>(
            0,
            (sum, p) =>
                sum +
                ((p['stock'] as num).toDouble() *
                    ((p['mrp'] as num).toDouble() - ((p['costPrice'] ?? 0) as num).toDouble())),
          );

          return Column(
            children: [
              // Header / Search
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ), // gray-200
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search products......',
                        hintStyle: const TextStyle(color: Color(0xFF8A8080)),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: Color(0xFF8A8080),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFD9D9D9).withOpacity(0.24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCEDFFD).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFF223960)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Total items: $totalItems',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF223960),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAE75).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFFFF6900)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Value of stock: ${totalStockValue.toInt()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF223960),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5FFF5).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFF00C479)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Profit of stock: ${totalProfit.toInt()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF223960),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _showAddProductDialog,
                        icon: Icon(LucideIcons.plus, size: 16),
                        label: const Text(
                          '+Add',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF223960),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No products found.',
                            style: TextStyle(color: Color(0xFF8A8080)),
                          ),
                        ),
                      ),
                    ...filteredProducts.map((product) {
                      final status = getStockStatus(
                        (product['stock'] as num).toInt(),
                        (product['lowStockAlert'] as num?)?.toInt() ?? 5,
                      );
                      final borderColor = getStockColor(status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF223960),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text('Feature coming soon!'),
                                            ),
                                          ),
                                      icon: const Icon(
                                        LucideIcons.edit_2,
                                        size: 16,
                                        color: Color(0xFF1FABEA),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text('Feature coming soon!'),
                                            ),
                                          ),
                                      icon: const Icon(
                                        LucideIcons.trash_2,
                                        size: 16,
                                        color: Color(0xFFD43500),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Feature coming soon!'),
                                        ),
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C479),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sell',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Qty',
                                        style: TextStyle(
                                          color: Color(0xFF8A8080),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Column(
                                        children: const [
                                          Icon(
                                            LucideIcons.chevron_up,
                                            size: 12,
                                            color: Color(0xFF8A8080),
                                          ),
                                          Icon(
                                            LucideIcons.chevron_down,
                                            size: 12,
                                            color: Color(0xFF8A8080),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (status == 'out')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF42018),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'OUT OF STOCK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (status == 'low')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD6BA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Low',
                                      style: TextStyle(
                                        color: Color(0xFFFF6900),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () =>
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Feature coming soon!'),
                                          ),
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6900),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ Stock',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'MRP',
                                      style: TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'â‚¹${product['mrp']}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Purchase',
                                      style: TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'â‚¹${product['costPrice'] ?? 0}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profit/unit',
                                      style: TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'â‚¹${((product['mrp'] as num).toDouble() - ((product['costPrice'] ?? 0) as num).toDouble())}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stock',
                                      style: TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      '${product['stock']} ${product['unit'] ?? "pcs"}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A8080),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


