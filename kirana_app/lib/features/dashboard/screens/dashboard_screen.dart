import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'label': "Today's Sales",
        'val': 'â‚¹7,240',
        'change': '+12%',
        'icon': LucideIcons.trending_up,
        'color': AppTheme.accent,
        'positive': true,
      },
      {
        'label': 'Total Bills',
        'val': '48',
        'change': '+8',
        'icon': LucideIcons.receipt,
        'color': const Color(0xFF0EA5E9),
        'positive': true,
      },
      {
        'label': 'Profit',
        'val': 'â‚¹2,180',
        'change': '+15%',
        'icon': LucideIcons.indian_rupee,
        'color': AppTheme.accent,
        'positive': true,
      },
      {
        'label': 'Credit Due',
        'val': 'â‚¹12,450',
        'change': '5 customers',
        'icon': LucideIcons.alert_circle,
        'color': const Color(0xFFF97316),
        'positive': false,
      },
    ];

    final topProducts = [
      {'name': 'Tata Salt 1kg', 'sold': '156 units sold', 'revenue': 'â‚¹3120'},
      {'name': 'Parle-G Biscuit', 'sold': '243 units sold', 'revenue': 'â‚¹2430'},
      {'name': 'Fortune Oil 1L', 'sold': '89 units sold', 'revenue': 'â‚¹7120'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
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
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sharma Kirana Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue (This Month)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'â‚¹1,86,450',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.trending_up,
                              color: AppTheme.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '18% vs last month',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Stats Grid
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  mainAxisExtent: 150,
),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Expanded(
  child:Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: stat['color'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        stat['icon'] as IconData,
        color: Colors.white,
        size: 20,
      ),
    ),

    const Spacer(),

    Text(
      stat['label'] as String,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppTheme.mutedForeground,
        fontSize: 12,
      ),
    ),

    const SizedBox(height: 4),

    FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        stat['val'] as String,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    ),

    const SizedBox(height: 2),

    Text(
      stat['change'] as String,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppTheme.accent,
        fontSize: 12,
      ),
    ),
  ],
)
)
                            )
                            .animate()
                            .fadeIn(delay: (100 * index).ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sales Chart
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weekly Sales',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Last 7 days performance',
                                style: TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 180,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (val, meta) => Text(
                                            val.toInt().toString(),
                                            style: const TextStyle(
                                              color: AppTheme.mutedForeground,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (val, meta) {
                                            const days = [
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                              'Sat',
                                              'Sun',
                                            ];
                                            if (val >= 0 && val < days.length) {
                                              return Text(
                                                days[val.toInt()],
                                                style: const TextStyle(
                                                  color:
                                                      AppTheme.mutedForeground,
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: 6,
                                    minY: 0,
                                    maxY: 10000,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: const [
                                          FlSpot(0, 4200),
                                          FlSpot(1, 5100),
                                          FlSpot(2, 3800),
                                          FlSpot(3, 6200),
                                          FlSpot(4, 5500),
                                          FlSpot(5, 8100),
                                          FlSpot(6, 7200),
                                        ],
                                        isCurved: true,
                                        color: const Color(0xFF0EA5E9),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // Category Distribution
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sales by Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 30,
                                        sections: [
                                          PieChartSectionData(
                                            color: const Color(0xFF0EA5E9),
                                            value: 42,
                                            title: '',
                                            radius: 30,
                                          ),
                                          PieChartSectionData(
                                            color: const Color(0xFF10B981),
                                            value: 28,
                                            title: '',
                                            radius: 30,
                                          ),
                                          PieChartSectionData(
                                            color: const Color(0xFFF59E0B),
                                            value: 18,
                                            title: '',
                                            radius: 30,
                                          ),
                                          PieChartSectionData(
                                            color: const Color(0xFF8B5CF6),
                                            value: 12,
                                            title: '',
                                            radius: 30,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildLegendItem(
                                          'Groceries',
                                          '42%',
                                          const Color(0xFF0EA5E9),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildLegendItem(
                                          'Snacks',
                                          '28%',
                                          const Color(0xFF10B981),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildLegendItem(
                                          'Beverages',
                                          '18%',
                                          const Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildLegendItem(
                                          'Others',
                                          '12%',
                                          const Color(0xFF8B5CF6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // Top Products
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Top Selling Products',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => context.go('/app/inventory'),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'View All',
                                          style: TextStyle(
                                            color: AppTheme.accent,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Icon(
                                          LucideIcons.chevron_right,
                                          color: AppTheme.accent,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...topProducts.map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.muted,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            LucideIcons.package,
                                            color: AppTheme.accent,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                product['sold']!,
                                                style: const TextStyle(
                                                  color:
                                                      AppTheme.mutedForeground,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          product['revenue']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // Quick Actions
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6B7280),
                                const Color(0xFF4B5563),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Low Stock Alert',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '8 products running low',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => context.go('/app/inventory'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // View Reports
                    InkWell(
                          onTap: () => context.go('/app/reports'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.trending_up,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'View Detailed Reports',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Analytics & insights',
                                        style: TextStyle(
                                          color: AppTheme.mutedForeground,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevron_right,
                                  color: AppTheme.mutedForeground,
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
        ),
      ],
    );
  }
}


