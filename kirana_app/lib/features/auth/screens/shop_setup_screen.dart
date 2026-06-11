import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  int step = 1;
  String shopName = '';
  String address = '';
  String gst = '';
  String phone = '';

  void handleContinue() {
    if (step == 1) {
      setState(() {
        step = 2;
      });
    } else {
      context.go('/app/dashboard');
    }
  }

  bool get isStep1Valid =>
      shopName.isNotEmpty && phone.isNotEmpty && address.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(child: step == 1 ? _buildStep1() : _buildStep2()),
              ElevatedButton(
                onPressed: (step == 1 && !isStep1Valid) ? null : handleContinue,
                child: Text(
                  step == 1 ? 'Continue' : 'Complete Setup',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStepIndicator(1, isActive: step >= 1, isCompleted: step > 1),
            Expanded(
              child: Container(
                height: 4,
                color: step >= 2
                    ? AppTheme.primary
                    : AppTheme.border.withOpacity(0.2),
              ),
            ),
            _buildStepIndicator(2, isActive: step >= 2, isCompleted: false),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          step == 1 ? 'Shop Details' : 'Upload Logo',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step == 1
              ? "Let's set up your shop profile"
              : 'Add your shop logo (optional)',
          style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    int stepNumber, {
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : AppTheme.border.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(LucideIcons.check, color: Colors.white, size: 20)
            : Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop Name *',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => shopName = val),
            decoration: const InputDecoration(
              hintText: 'e.g., Sharma Kirana Store',
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Phone Number *',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => phone = val),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Enter contact number'),
          ),
          const SizedBox(height: 16),

          const Text(
            'Address *',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => address = val),
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Shop address'),
          ),
          const SizedBox(height: 16),

          const Text(
            'GST Number (Optional)',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => gst = val),
            decoration: const InputDecoration(hintText: '22AAAAA0000A1Z5'),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.border.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.muted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.upload,
                    color: AppTheme.mutedForeground,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Click to upload logo',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PNG, JPG up to 5MB',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.border.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.store, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName.isNotEmpty ? shopName : 'Your Shop Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        address.isNotEmpty ? address : 'Address',
                        style: const TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }
}


