import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final customers = [
    {
      'id': '1',
      'name': 'Rajesh Kumar',
      'phone': '+91 93765 28765',
      'balance': 2450.0,
    },
    {
      'id': '2',
      'name': 'Priya Sharma',
      'phone': '+91 09245 18761',
      'balance': 1800.0,
    },
    {
      'id': '3',
      'name': 'Rakesh Varma',
      'phone': '+91 45634 78567',
      'balance': 200.0,
    },
    {
      'id': '4',
      'name': 'Prasad Mane',
      'phone': '+91 98067 25769',
      'balance': 500.0,
    },
    {
      'id': '5',
      'name': 'Ajay Wanjule',
      'phone': '+91 87306 26597',
      'balance': 1000.0,
    },
    {
      'id': '6',
      'name': 'Anuja Hire',
      'phone': '+91 67298 20987',
      'balance': 1600.0,
    },
  ];

  double get totalOutstanding =>
      customers.fold(0, (sum, c) => sum + (c['balance'] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6900), Color(0xFFFFB078)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Khata',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customers.length} customers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon!')),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6900),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D6).withOpacity(0.35),
                    border: Border.all(color: const Color(0xFFFF6900)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Outstanding',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalOutstanding.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDBDBDB)),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAD74).withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.users,
                              color: Color(0xFFFF6901),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF223960),
                                  ),
                                ),
                                Text(
                                  customer['phone'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF8A8080),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Outstanding Balance',
                                  style: TextStyle(
                                    color: Color(0xFF8A8080),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '₹${(customer['balance'] as double).toInt()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6901),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                LucideIcons.chevronRight,
                                color: Color(0xFF8A8080),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (50 * index).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
