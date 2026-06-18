import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String searchQuery = '';
  String categoryFilter = 'All';

  String getStockStatus(int stock, int alert) {
    if (stock == 0) return 'out';
    if (stock <= alert) return 'low';
    return 'good';
  }

  Color getStockColor(String status) {
    if (status == 'out') return const Color(0xFFEF4444);
    if (status == 'low') return const Color(0xFFF97316);
    return const Color(0xFF22C55E);
  }

  String? _findDuplicateBarcode(String barcode, {String? excludeId}) {
    if (barcode.isEmpty) return null;
    final products = ref.read(inventoryProvider).value ?? [];
    for (final p in products) {
      final id = p['_id'] ?? p['id'];
      if (excludeId != null && id == excludeId) continue;
      if (p['barcode'] == barcode) return p['name'] as String?;
    }
    return null;
  }

  void _showAddProductDialog({String? prefilledBarcode}) {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController(text: prefilledBarcode ?? '');
    final mrpCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String category = 'Others';

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
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          hintText: 'Scan or type',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        // Close the bottom sheet first
                        Navigator.of(ctx).pop();
                        // Then open scanner
                        final barcode = await openBarcodeScanner(context);
                        if (barcode != null && mounted) {
                          // Re-open dialog with scanned barcode
                          _showAddProductDialog(prefilledBarcode: barcode);
                        }
                      },
                      icon: const Icon(LucideIcons.scanLine, color: Color(0xFF223960)),
                      tooltip: 'Scan barcode',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (ctx, setDialogState) => DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Others', child: Text('Others')),
                    ],
                    onChanged: (v) => setDialogState(() => category = v ?? 'Others'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mrpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'MRP / Selling Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Stock'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && mrpCtrl.text.isNotEmpty) {
                        // Check for duplicate barcode
                        if (barcodeCtrl.text.isNotEmpty) {
                          final existingName = _findDuplicateBarcode(barcodeCtrl.text);
                          if (existingName != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Barcode already used by "$existingName"')),
                            );
                            return;
                          }
                        }
                        try {
                          await ref.read(inventoryProvider.notifier).addProduct({
                            'name': nameCtrl.text,
                            'barcode': barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : null,
                            'category': category,
                            'mrp': double.tryParse(mrpCtrl.text) ?? 0,
                            'costPrice': double.tryParse(costCtrl.text) ?? 0,
                            'stock': double.tryParse(stockCtrl.text) ?? 0,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add product: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223960),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final productId = product['_id'] ?? product['id'];
    final nameCtrl = TextEditingController(text: product['name'] as String? ?? '');
    final barcodeCtrl = TextEditingController(text: product['barcode'] as String? ?? '');
    final mrpCtrl = TextEditingController(text: '${product['mrp'] ?? ''}');
    final costCtrl = TextEditingController(text: '${product['costPrice'] ?? ''}');
    final stockCtrl = TextEditingController(text: '${product['stock'] ?? 0}');
    final lowStockCtrl = TextEditingController(text: '${product['lowStock'] ?? 5}');
    String category = product['category'] as String? ?? 'Others';

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
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          hintText: 'Scan or type',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final barcode = await openBarcodeScanner(context);
                        if (barcode != null && mounted) {
                          _showEditProductDialog({...product, 'barcode': barcode});
                        }
                      },
                      icon: const Icon(LucideIcons.scanLine, color: Color(0xFF223960)),
                      tooltip: 'Scan barcode',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (ctx, setDialogState) => DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Others', child: Text('Others')),
                    ],
                    onChanged: (v) => setDialogState(() => category = v ?? 'Others'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mrpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'MRP / Selling Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lowStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Low Stock Alert'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && mrpCtrl.text.isNotEmpty) {
                        // Check for duplicate barcode (exclude current product)
                        if (barcodeCtrl.text.isNotEmpty) {
                          final existingName = _findDuplicateBarcode(barcodeCtrl.text, excludeId: productId);
                          if (existingName != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Barcode already used by "$existingName"')),
                            );
                            return;
                          }
                        }
                        ref.read(inventoryProvider.notifier).updateProduct(productId, {
                          'name': nameCtrl.text,
                          'barcode': barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : null,
                          'category': category,
                          'mrp': double.tryParse(mrpCtrl.text) ?? 0,
                          'costPrice': double.tryParse(costCtrl.text) ?? 0,
                          'stock': double.tryParse(stockCtrl.text) ?? 0,
                          'lowStock': double.tryParse(lowStockCtrl.text) ?? 5,
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223960),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  void _confirmDelete(Map<String, dynamic> product) {
    final productId = product['_id'] ?? product['id'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(inventoryProvider.notifier).deleteProduct(productId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD43500),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
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
                LucideIcons.refreshCw,
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
          final filteredProducts = products.where((p) {
            final name = (p['name'] as String).toLowerCase();
            final matchesSearch = name.contains(searchQuery.toLowerCase());
            final matchesCategory = categoryFilter == 'All' || p['category'] == categoryFilter;
            return matchesSearch && matchesCategory;
          }).toList();
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search products......',
                        hintStyle: const TextStyle(color: Color(0xFF8A8080)),
                        prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF8A8080)),
                        filled: true,
                        fillColor: const Color(0xFFD9D9D9).withOpacity(0.24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'Groceries', 'Snacks', 'Beverages', 'Others'].map((cat) {
                          final isSelected = categoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat, style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : const Color(0xFF223960),
                              )),
                              selected: isSelected,
                              onSelected: (_) => setState(() => categoryFilter = cat),
                              selectedColor: const Color(0xFF223960),
                              backgroundColor: const Color(0xFFF6F6F6),
                              checkmarkColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCEDFFD).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFF223960)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Total items: $totalItems',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF223960), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAE75).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFFFF6900)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Value of stock: ${totalStockValue.toInt()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF223960), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5FFF5).withOpacity(0.24),
                              border: Border.all(color: const Color(0xFF00C479)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Profit of stock: ${totalProfit.toInt()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF223960), fontWeight: FontWeight.w500),
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
                    // Two buttons: Add and Scan
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddProductDialog(),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF223960),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final barcode = await openBarcodeScanner(context);
                            if (barcode != null && mounted) {
                              _showAddProductDialog(prefilledBarcode: barcode);
                            }
                          },
                          icon: const Icon(LucideIcons.scanLine, size: 16),
                          label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6900),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No products found.', style: TextStyle(color: Color(0xFF8A8080))),
                        ),
                      ),
                    ...filteredProducts.map((product) {
                      final status = getStockStatus(
                        (product['stock'] as num).toInt(),
                        (product['lowStock'] as num?)?.toInt() ?? 5,
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] as String,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF223960)),
                                      ),
                                      if (product['barcode'] != null &&
                                          (product['barcode'] as String).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.scanLine, size: 12, color: Color(0xFF8A8080)),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['barcode'] as String,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8080)),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _showEditProductDialog(product),
                                      icon: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF1FABEA)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _confirmDelete(product),
                                      icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFD43500)),
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
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Feature coming soon!')),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C479),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Sell', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text('Qty', style: TextStyle(color: Color(0xFF8A8080), fontWeight: FontWeight.w500)),
                                      SizedBox(width: 4),
                                      Column(children: [
                                        Icon(LucideIcons.chevronUp, size: 12, color: Color(0xFF8A8080)),
                                        Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFF8A8080)),
                                      ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (status == 'out')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFF42018), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                else if (status == 'low')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(color: const Color(0xFFFFD6BA), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Low', style: TextStyle(color: Color(0xFFFF6900), fontSize: 14, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Feature coming soon!')),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6900),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('+ Stock', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    const Text('MRP', style: TextStyle(color: Color(0xFF8A8080), fontSize: 10)),
                                    Text('₹${product['mrp']}', style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Purchase', style: TextStyle(color: Color(0xFF8A8080), fontSize: 10)),
                                    Text('₹${product['costPrice'] ?? 0}', style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Profit/unit', style: TextStyle(color: Color(0xFF8A8080), fontSize: 10)),
                                    Text(
                                      '₹${((product['mrp'] as num).toDouble() - ((product['costPrice'] ?? 0) as num).toDouble())}',
                                      style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Stock', style: TextStyle(color: Color(0xFF8A8080), fontSize: 10)),
                                    Text(
                                      '${product['stock']} ${product['unit'] ?? "pcs"}',
                                      style: const TextStyle(color: Color(0xFF8A8080), fontSize: 12),
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
