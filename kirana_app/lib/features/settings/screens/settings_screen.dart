import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../billing/providers/bills_provider.dart';
import '../../khata/providers/khata_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSending = false;
  bool _isSavingShop = false;

  Future<String?> _showOtpDialog() async {
    _otpCtrl.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify OTP'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the OTP sent to your email'),
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _otpCtrl.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_nameCtrl.text.isEmpty && _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to update')),
      );
      return;
    }

    setState(() => _isOtpSending = true);
    try {
      await ref.read(settingsProvider).sendSettingsOtp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
      setState(() => _isOtpSending = false);
      return;
    }
    setState(() => _isOtpSending = false);

    if (!mounted) return;
    final otp = await _showOtpDialog();
    if (otp == null || otp.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(settingsProvider).updateWithOtp(
        name: _nameCtrl.text,
        password: _passCtrl.text,
        otp: otp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        _nameCtrl.clear();
        _passCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUpiId() async {
    if (_upiIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a UPI ID')),
      );
      return;
    }

    setState(() => _isOtpSending = true);
    try {
      await ref.read(settingsProvider).sendSettingsOtp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
      setState(() => _isOtpSending = false);
      return;
    }
    setState(() => _isOtpSending = false);

    if (!mounted) return;
    final otp = await _showOtpDialog();
    if (otp == null || otp.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(settingsProvider).updateWithOtp(
        upiId: _upiIdCtrl.text.trim(),
        otp: otp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI ID updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateShopDetails() async {
    if (_shopNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop name is required')),
      );
      return;
    }

    setState(() => _isSavingShop = true);
    try {
      await ref.read(settingsProvider).updateShop(
        name: _shopNameCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop details updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingShop = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logoutCurrentUserCache();

    ref.invalidate(inventoryProvider);
    ref.invalidate(billsProvider);
    ref.invalidate(khataProvider);
    ref.invalidate(outstandingSummaryProvider);

    await ref.read(authRepositoryProvider).logout();
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _upiIdCtrl.dispose();
    _shopNameCtrl.dispose();
    _gstinCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = isLandscape ? 48.0 : 24.0;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF223960),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: isLandscape || isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildShopSection(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildProfileSection(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildPaymentSection(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShopSection(),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildProfileSection(),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildPaymentSection(),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildLogoutSection(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _shopNameCtrl,
          decoration: InputDecoration(
            labelText: 'Shop Name',
            prefixIcon: const Icon(LucideIcons.store),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _gstinCtrl,
          decoration: InputDecoration(
            labelText: 'GST Number (Optional)',
            hintText: '22AAAAA0000A1Z5',
            prefixIcon: const Icon(LucideIcons.fileText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSavingShop ? null : _updateShopDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF223960),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSavingShop
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Shop Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Update Name',
            prefixIcon: const Icon(LucideIcons.user),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(LucideIcons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isLoading || _isOtpSending) ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isOtpSending
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Sending OTP...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                )
              : _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'UPI ID for QR code generation during billing',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _upiIdCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'e.g. shopname@upi',
            prefixIcon: const Icon(LucideIcons.qrCode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isLoading || _isOtpSending) ? null : _updateUpiId,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6900),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isOtpSending
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Sending OTP...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                )
              : _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save UPI ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(LucideIcons.logOut, color: Colors.red),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
