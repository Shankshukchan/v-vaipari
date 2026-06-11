import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': LucideIcons.receipt, 'text': 'Fast Billing'},
      {'icon': LucideIcons.package_check, 'text': 'Inventory'},
      {'icon': LucideIcons.users, 'text': 'Customer Khata'},
      {'icon': LucideIcons.trending_up, 'text': 'Analytics'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary,
                AppTheme.primary.withOpacity(0.9),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    LucideIcons.store,
                    size: 64,
                    color: Colors.white,
                  ),
                ),

                // Title
                const Text(
                  'Welcome to Kirana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Transform your shop with smart billing, inventory management, and powerful analytics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 40),

                // Features Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: features.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final feature = features[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            feature['icon'] as IconData,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              feature['text'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .scale();
                  },
                ),

                const SizedBox(height: 32),

                // Trust Badge
                

                const SizedBox(height: 40),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(
                      begin: 20,
                      end: 0,
                    ),

                const SizedBox(height: 12),

                // Skip Button
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Skip to Demo â†’',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 20),
              ],
            ).animate().fadeIn(duration: 500.ms).moveY(
                  begin: 20,
                  end: 0,
                ),
          ),
        ),
      ),
    );
  }
}

