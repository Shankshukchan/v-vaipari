import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<Map<String, dynamic>> cart = [
    // Pre-filled just for demo matching React
    {
      'id': '1',
      'name': 'Tata Salt 1kg',
      'price': 20.0,
      'quantity': 2,
      'mrp': 22.0,
    },
    {
      'id': '2',
      'name': 'Parle-G Biscuit',
      'price': 10.0,
      'quantity': 5,
      'mrp': 12.0,
    },
  ];

  String customerName = '';
  String customerPhone = '';

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get profit => cart.fold(
    0,
    (sum, item) => sum + (item['price'] * item['quantity'] * 0.15),
  );
  double get total => subtotal + (subtotal * 0.05); // Assuming 5% GST for demo

  void removeItem(String id) {
    setState(() {
      cart.removeWhere((item) => item['id'] == id);
    });
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              ),
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
          // Header Additions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon!')),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F6F6),
                      foregroundColor: const Color(0xFF223960),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Invoice',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  ),
                  icon: const Icon(
                    LucideIcons.qrCode,
                    color: Color(0xFFFF6900),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF6F6F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFE5E7EB)),

          // Product Selection bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9).withOpacity(0.24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Select your product......',
                          style: TextStyle(
                            color: Color(0xFF8A8080),
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronDown,
                          color: Color(0xFF8A8080),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9).withOpacity(0.24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        LucideIcons.minus,
                        color: Color(0xFF8A8080),
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text('0', style: TextStyle(color: Color(0xFF8A8080))),
                      SizedBox(width: 12),
                      Icon(
                        LucideIcons.plus,
                        color: Color(0xFF8A8080),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      color: Color(0xFF223960),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                          child: const Icon(
                            LucideIcons.scan,
                            size: 40,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cart is empty',
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 16,
                          ),
                        ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
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
                                      '${item['quantity']} packet × ₹${item['price']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF223960),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF223960),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => removeItem(item['id']),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF25955,
                                          ).withOpacity(0.24),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.x,
                                          color: Color(0xFFF42018),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
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

                      // Customer Details & Summary
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF223960), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Name:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (v) =>
                                  setState(() => customerName = v),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter name',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Contact:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (v) =>
                                  setState(() => customerPhone = v),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '+91 XXXXX XXXXX',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Profit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${profit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF00C479),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Feature coming soon!'),
                              ),
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .transparent, // We use a gradient container below
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                              'Generate Bill & Print',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
}
