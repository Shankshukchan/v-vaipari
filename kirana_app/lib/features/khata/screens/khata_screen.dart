import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'create_khata_screen.dart';
import 'khata_detail_screen.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  // Your dummy customer data
  final List<Map<String, dynamic>> customers = [
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
      'balance': -350.0, // Negative means they paid in advance (Jama)
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Basic calculation for total outstanding credit
    double totalOutstanding = customers
        .where((c) => c['balance'] > 0)
        .fold(0.0, (sum, c) => sum + c['balance']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Ledger'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Total Balance Card Header with Animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Outstanding Credit (Udhaar)',
                  style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  'â‚¹ ${totalOutstanding.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.red.shade700
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          
          // Customer Ledger List View
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final bool isUdhaar = customer['balance'] > 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Icon(LucideIcons.user, color: Colors.indigo),
                    ),
                    title: Text(
                      customer['name'], 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text(customer['phone']),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'â‚¹ ${customer['balance'].abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUdhaar ? Colors.red.shade600 : Colors.green.shade600,
                          ),
                        ),
                        Text(
                          isUdhaar ? 'Due' : 'Advance',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUdhaar ? Colors.red.shade400 : Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KhataDetailScreen(customer: customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // CreateKhataScreen is not available in this codebase yet.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Khata screen is not set up yet.')),
          );
        },
        label: const Text('New Khata'),
        icon: Icon(LucideIcons.user_plus),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}

