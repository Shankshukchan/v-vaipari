import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class KhataDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const KhataDetailScreen({super.key, required this.customer});

  @override
  State<KhataDetailScreen> createState() => _KhataDetailScreenState();
}

class _KhataDetailScreenState extends State<KhataDetailScreen> {
  late String customerName;
  late String customerPhone;
  late double customerBalance;

  @override
  void initState() {
    super.initState();
    // Initialize state variables with data passed from dashboard
    customerName = widget.customer['name'];
    customerPhone = widget.customer['phone'];
    customerBalance = widget.customer['balance'];
  }

  // 1. EDIT KHATA LOGIC
  void _showEditDialog() {
    final nameController = TextEditingController(text: customerName);
    final phoneController = TextEditingController(text: customerPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Khata Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                customerName = nameController.text.trim();
                customerPhone = phoneController.text.trim();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Khata updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. DELETE / ARCHIVE KHATA LOGIC
  void _confirmDeleteKhata() {
    // Validation Rule: Shopkeeper shouldn't delete a customer who still owes money!
    if (customerBalance > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Account', style: TextStyle(color: Colors.red)),
          content: Text('$customerName still has a pending balance of â‚¹${customerBalance.toStringAsFixed(2)}. You must clear the balance before deleting this account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
      return;
    }

    // Safe to delete/archive confirmation if balance is 0 or advance
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Khata Profile?'),
        content: Text('Are you sure you want to permanently close the ledger for $customerName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to main dashboard screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Khata profile for $customerName has been removed.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dummy transaction history for display
    final List<Map<String, dynamic>> transactions = [
      {
        'date': '11 Jun 2026',
        'items': 'Rice 5kg, Cooking Oil 1L',
        'amount': 450.00,
        'type': 'DEBIT'
      },
      {
        'date': '05 Jun 2026',
        'items': 'Cash Payment Received',
        'amount': 200.00,
        'type': 'CREDIT'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$customerName\'s Ledger'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.edit_3),
            onPressed: _showEditDialog, // Triggers Edit Form Dialog
          ),
          IconButton(
            icon: Icon(LucideIcons.trash_2),
            onPressed: _confirmDeleteKhata, // Triggers Validation & Delete Dialog
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Balance Display Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Outstanding Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'â‚¹ ${customerBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 32, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: $customerPhone',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Transaction Statement List
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isDebit = tx['type'] == 'DEBIT';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(tx['items'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(tx['date']),
                    trailing: Text(
                      '${isDebit ? "+" : "-"} â‚¹${tx['amount'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDebit ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

