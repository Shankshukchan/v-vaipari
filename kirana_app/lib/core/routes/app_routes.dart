import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/shop_setup_screen.dart';
import '../../core/layouts/main_layout.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/low_stock_screen.dart';
import '../../features/billing/screens/billing_screen.dart';
import '../../features/khata/screens/khata_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ShopSetupScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/app/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app/billing',
            builder: (context, state) => const BillingScreen(),
          ),
          GoRoute(
            path: '/app/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/app/khata',
            builder: (context, state) => const KhataScreen(),
          ),
          GoRoute(
            path: '/app/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/app/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/app/low-stock',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LowStockScreen(),
      ),
    ],
    // TODO: Add redirect logic based on auth state
  );
});
