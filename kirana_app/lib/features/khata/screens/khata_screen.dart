import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../providers/khata_provider.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(khataProvider.notifier).fetchCustomers();
      ref.read(outstandingSummaryProvider.notifier).refresh();
    });
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter customer name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '10-digit mobile number',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: 'Opening Balance (optional)',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final balance =
                  double.tryParse(balanceController.text.trim()) ?? 0;

              if (name.isEmpty || phone.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter valid name and phone')),
                );
                return;
              }

              await ref.read(khataProvider.notifier).addCustomer({
                'name': name,
                'phone': phone,
                'balance': balance,
              });
              ref.read(outstandingSummaryProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6900),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    final nameController =
        TextEditingController(text: customer['name'] as String? ?? '');
    final phoneController =
        TextEditingController(text: customer['phone'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter valid name and phone')),
                );
                return;
              }
              await ref.read(khataProvider.notifier).updateCustomer(
                    customer['_id'] as String,
                    {'name': name, 'phone': phone},
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF223960),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(Map<String, dynamic> customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CustomerDetailScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(khataProvider);
    final summaryAsync = ref.watch(outstandingSummaryProvider);

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
                        customersAsync.when(
                          loading: () => const Text(
                            'Loading...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          error: (_, __) => const Text(
                            'Error loading',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          data: (customers) => Text(
                            '${customers.length} customers',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _showAddCustomerDialog,
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
                      summaryAsync.when(
                        loading: () => const Text(
                          '₹0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        error: (_, __) => const Text(
                          '₹0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        data: (summary) => Text(
                          '₹${((summary['totalOutstanding'] as num?)?.toDouble() ?? 0).toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: const TextStyle(color: Color(0xFF8A8080)),
                prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF8A8080)),
                filled: true,
                fillColor: const Color(0xFFF6F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        size: 48, color: Color(0xFF8A8080)),
                    const SizedBox(height: 16),
                    Text('Error: $err',
                        style: const TextStyle(color: Color(0xFF8A8080))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(khataProvider.notifier)
                          .fetchCustomers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE7D6).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.users,
                              size: 40, color: Color(0xFFFF6901)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No customers yet',
                          style: TextStyle(
                              color: Color(0xFF8A8080), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first customer',
                          style: TextStyle(
                              color: Color(0xFF8A8080), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = customers.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  final name = (c['name'] as String? ?? '').toLowerCase();
                  final phone = (c['phone'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      phone.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching customers',
                      style: TextStyle(color: Color(0xFF8A8080), fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(khataProvider.notifier).fetchCustomers();
                    await ref.read(outstandingSummaryProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      final balance =
                          (customer['balance'] as num?)?.toDouble() ?? 0;

                      return Dismissible(
                        key: Key(customer['_id'] as String),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFF42018),
                          child: const Icon(LucideIcons.trash2,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Customer'),
                              content: Text(
                                  'Delete ${customer['name']}? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFF42018),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref.read(khataProvider.notifier).deleteCustomer(
                              customer['_id'] as String);
                          ref
                              .read(outstandingSummaryProvider.notifier)
                              .refresh();
                        },
                        child: InkWell(
                          onTap: () => _showCustomerDetail(customer),
                          onLongPress: () =>
                              _showEditCustomerDialog(customer),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFFDBDBDB)),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.02),
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
                                    color: const Color(0xFFFFAD74)
                                        .withOpacity(0.5),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      '₹${balance.toInt()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: balance > 0
                                            ? const Color(0xFFFF6901)
                                            : const Color(0xFF00C479),
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
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (50 * index).ms)
                          .slideY(begin: 0.1, end: 0);
                    },
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

// ─── Customer Detail Screen ──────────────────────────────────────────────────

class _CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const _CustomerDetailScreen({required this.customer});

  @override
  ConsumerState<_CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends ConsumerState<_CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearKhata() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Khata'),
        content: Text(
          'Mark all pending bills as paid for ${widget.customer['name']}? This will reset their balance to ₹0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C479),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Khata'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dio = ref.read(dioProvider);
      try {
        await dio.post('/customers/${widget.customer['_id']}/clear');
        ref.read(khataProvider.notifier).fetchCustomers();
        ref.read(outstandingSummaryProvider.notifier).refresh();
        ref.invalidate(customerTransactionsProvider(widget.customer['_id'] as String));
        ref.invalidate(customerBillsProvider(widget.customer['_id'] as String));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Khata cleared successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear khata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
        customerTransactionsProvider(widget.customer['_id'] as String));
    final billsAsync = ref.watch(
        customerBillsProvider(widget.customer['_id'] as String));
    final balance =
        (widget.customer['balance'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6900),
        foregroundColor: Colors.white,
        title: Text(widget.customer['name'] as String),
        elevation: 0,
        actions: [
          if (balance > 0)
            IconButton(
              icon: const Icon(LucideIcons.checkCircle),
              onPressed: _clearKhata,
              tooltip: 'Clear Khata',
            ),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              _showAddTransactionDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Bills'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6900), Color(0xFFFFB078)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customer['phone'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Outstanding',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '₹${balance.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Transactions Tab
                transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.receipt,
                                size: 48, color: Color(0xFF8A8080)),
                            SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                  color: Color(0xFF8A8080), fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        final isCredit = txn['type'] == 'CREDIT';
                        final txnAmount =
                            (txn['amount'] as num?)?.toDouble() ?? 0;
                        String dateStr = '';
                        if (txn['createdAt'] != null) {
                          try {
                            final dt =
                                DateTime.parse(txn['createdAt'] as String);
                            dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
                          } catch (_) {}
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? const Color(0xFFFF6900).withOpacity(0.1)
                                      : const Color(0xFF00C479).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit
                                      ? LucideIcons.arrowUpRight
                                      : LucideIcons.arrowDownLeft,
                                  color: isCredit
                                      ? const Color(0xFFFF6900)
                                      : const Color(0xFF00C479),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCredit ? 'CREDIT' : 'DEBIT',
                                      style: TextStyle(
                                        color: isCredit
                                            ? const Color(0xFFFF6900)
                                            : const Color(0xFF00C479),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (txn['note'] != null &&
                                        (txn['note'] as String).isNotEmpty)
                                      Text(
                                        txn['note'] as String,
                                        style: const TextStyle(
                                          color: Color(0xFF8A8080),
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (dateStr.isNotEmpty)
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: Color(0xFF8A8080),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}₹${txnAmount.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCredit
                                      ? const Color(0xFFFF6900)
                                      : const Color(0xFF00C479),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // Bills Tab
                billsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (bills) {
                    if (bills.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.receipt,
                                size: 48, color: Color(0xFF8A8080)),
                            SizedBox(height: 16),
                            Text(
                              'No bills yet',
                              style: TextStyle(
                                  color: Color(0xFF8A8080), fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        final items = bill['items'] as List<dynamic>? ?? [];
                        final total = (bill['total'] as num?)?.toDouble() ?? 0;
                        final status = bill['status'] as String? ?? 'PAID';
                        final paymentMode = bill['paymentMode'] as String? ?? 'CASH';
                        String dateStr = '';
                        if (bill['createdAt'] != null) {
                          try {
                            final dt =
                                DateTime.parse(bill['createdAt'] as String);
                            dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
                          } catch (_) {}
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                        color: Color(0xFF8A8080), fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'PAID'
                                              ? const Color(0xFFE5FFF5)
                                              : const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: status == 'PAID'
                                                ? const Color(0xFF00C479)
                                                : const Color(0xFFFF6900),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['name']} x${item['qty'] ?? item['quantity']}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF223960)),
                                      ),
                                    ),
                                    Text(
                                      '₹${((item['total'] as num?) ?? ((item['price'] as num) * ((item['qty'] ?? item['quantity']) as num))).toStringAsFixed(2)}',
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
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String transactionType = 'CREDIT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Transaction - ${widget.customer['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Credit', style: TextStyle(fontSize: 13)),
                      value: 'CREDIT',
                      groupValue: transactionType,
                      onChanged: (v) =>
                          setDialogState(() => transactionType = v!),
                      activeColor: const Color(0xFFFF6900),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Debit', style: TextStyle(fontSize: 13)),
                      value: 'DEBIT',
                      groupValue: transactionType,
                      onChanged: (v) =>
                          setDialogState(() => transactionType = v!),
                      activeColor: const Color(0xFF00C479),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Payment received',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                await ref.read(khataProvider.notifier).addTransaction(
                      widget.customer['_id'] as String,
                      type: transactionType,
                      amount: amount,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );
                ref.read(outstandingSummaryProvider.notifier).refresh();
                ref.invalidate(customerTransactionsProvider(
                    widget.customer['_id'] as String));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: transactionType == 'CREDIT'
                    ? const Color(0xFFFF6900)
                    : const Color(0xFF00C479),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
