import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/screens/low_stock_screen.dart';

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/bills/dashboard');
  if (response.data['success'] == true) {
    return Map<String, dynamic>.from(response.data['data']);
  }
  throw Exception('Failed to load dashboard');
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _userName = 'Owner';
  String _shopName = 'My Store';
  bool _isLoadingProfile = true;
  Timer? _refreshTimer;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(dashboardStatsProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    if (path == '/app/dashboard' && path != _currentPath) {
      _currentPath = path;
      ref.invalidate(dashboardStatsProvider);
    } else if (path != '/app/dashboard') {
      _currentPath = path;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ref.read(authRepositoryProvider).getCurrentUser();
      setState(() {
        _userName = data['name'] as String? ?? 'Owner';
        final shop = data['shop'];
        _shopName = shop != null ? (shop['name'] as String? ?? 'My Store') : 'My Store';
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Color(0xFF8A8080)),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Color(0xFF8A8080))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) {
          try {
          final todaySales = (stats['todaySales'] as num?)?.toDouble() ?? 0;
          final todayBillsCount = (stats['todayBillsCount'] as num?)?.toInt() ?? 0;
          final monthRevenue = (stats['monthRevenue'] as num?)?.toDouble() ?? 0;
          final monthProfit = (stats['monthProfit'] as num?)?.toDouble() ?? 0;
          final totalCreditDue = (stats['totalCreditDue'] as num?)?.toDouble() ?? 0;
          final creditCustomers = (stats['creditCustomers'] as num?)?.toInt() ?? 0;
          final lowStockCount = (stats['lowStockCount'] as num?)?.toInt() ?? 0;
          final topProducts = (stats['topProducts'] as List<dynamic>?) ?? [];
          final dailySales = (stats['dailySales'] as List<dynamic>?) ?? [];
          final rawCategory = stats['categoryBreakdown'];
          final categoryBreakdown = rawCategory is Map ? Map<String, dynamic>.from(rawCategory) : <String, dynamic>{};

          final groceriesCount = (categoryBreakdown['Groceries'] as num?)?.toInt() ?? 0;
          final snacksCount = (categoryBreakdown['Snacks'] as num?)?.toInt() ?? 0;
          final beveragesCount = (categoryBreakdown['Beverages'] as num?)?.toInt() ?? 0;
          final othersCount = (categoryBreakdown['Others'] as num?)?.toInt() ?? 0;
          final hasCategoryData = groceriesCount > 0 || snacksCount > 0 || beveragesCount > 0 || othersCount > 0;

          final hasDailyData = dailySales.isNotEmpty && dailySales.any((s) => (s as num).toDouble() > 0);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              await ref.read(dashboardStatsProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.9)],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20,
                      right: 20,
                      bottom: 24,
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
                                    'Welcome, ${_isLoadingProfile ? '' : _userName}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isLoadingProfile ? 'Loading...' : _shopName,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Revenue (This Month)', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('₹${monthRevenue.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(LucideIcons.trendingUp, color: AppTheme.accent, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Profit: ₹${monthProfit.toInt()}', style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      children: [
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _buildStatCard("Today's Sales", '₹${todaySales.toInt()}', '${todayBillsCount} bills', LucideIcons.trendingUp, const Color(0xFF0EA5E9))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Profit', '₹${monthProfit.toInt()}', 'This month', LucideIcons.indianRupee, const Color(0xFF10B981))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Credit Due', '₹${totalCreditDue.toInt()}', '$creditCustomers customers', LucideIcons.alertCircle, const Color(0xFFF97316))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Low Stock', '$lowStockCount', 'Products low', LucideIcons.package, const Color(0xFFEF4444))),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Weekly Sales Chart
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Weekly Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('Last 7 days', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: !hasDailyData
                                    ? const Center(child: Text('No sales data yet', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)))
                                    : LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(show: false),
                                          titlesData: FlTitlesData(
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 36,
                                                getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9)),
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (val, meta) {
                                                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                                  if (val >= 0 && val < days.length) return Text(days[val.toInt()], style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10));
                                                  return const Text('');
                                                },
                                              ),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          minX: 0,
                                          maxX: 6,
                                          minY: 0,
                                          maxY: dailySales.isEmpty ? 100.0 : (dailySales.cast<num>().reduce((a, b) => a > b ? a : b).toDouble() * 1.3 + 100),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: List.generate(7, (i) {
                                                final val = i < dailySales.length ? (dailySales[i] as num).toDouble() : 0.0;
                                                return FlSpot(i.toDouble(), val);
                                              }),
                                              isCurved: true,
                                              color: const Color(0xFF0EA5E9),
                                              barWidth: 2.5,
                                              isStrokeCapRound: true,
                                              dotData: const FlDotData(show: true),
                                              belowBarData: BarAreaData(show: true, color: const Color(0xFF0EA5E9).withOpacity(0.1)),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Category Distribution
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Products by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: !hasCategoryData
                                        ? const Center(child: Text('No data', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 11)))
                                        : PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 25,
                                              sections: [
                                                if (groceriesCount > 0)
                                                  PieChartSectionData(color: const Color(0xFF0EA5E9), value: groceriesCount.toDouble(), title: '', radius: 25),
                                                if (snacksCount > 0)
                                                  PieChartSectionData(color: const Color(0xFF10B981), value: snacksCount.toDouble(), title: '', radius: 25),
                                                if (beveragesCount > 0)
                                                  PieChartSectionData(color: const Color(0xFFF59E0B), value: beveragesCount.toDouble(), title: '', radius: 25),
                                                if (othersCount > 0)
                                                  PieChartSectionData(color: const Color(0xFF8B5CF6), value: othersCount.toDouble(), title: '', radius: 25),
                                              ],
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildLegendItem('Groceries', '$groceriesCount', const Color(0xFF0EA5E9)),
                                        const SizedBox(height: 6),
                                        _buildLegendItem('Snacks', '$snacksCount', const Color(0xFF10B981)),
                                        const SizedBox(height: 6),
                                        _buildLegendItem('Beverages', '$beveragesCount', const Color(0xFFF59E0B)),
                                        const SizedBox(height: 6),
                                        _buildLegendItem('Others', '$othersCount', const Color(0xFF8B5CF6)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Top Products
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Top Selling Products', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  GestureDetector(
                            onTap: () => context.push('/app/low-stock'),
                                    child: const Text('View All', style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (topProducts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('No sales data yet', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                                )
                              else
                                ...topProducts.take(3).map(
                                  (product) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(LucideIcons.package, color: AppTheme.accent, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text('${product['qty'] ?? 0} sold', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Text('₹${(product['revenue'] ?? 0).toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Low Stock Alert
                        if (lowStockCount > 0)
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LowStockScreen())),                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Low Stock Alert', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('$lowStockCount products running low', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                    child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 14),

                        // View Reports
                        GestureDetector(
                          onTap: () => context.go('/app/reports'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(LucideIcons.trendingUp, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('View Detailed Reports', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                      Text('Analytics & insights', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(LucideIcons.chevronRight, color: AppTheme.mutedForeground, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          } catch (e) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('$e', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(dashboardStatsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildStatCard(String label, String value, String change, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
          const SizedBox(height: 1),
          Text(change, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Text(value, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
      ],
    );
  }
}
