import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final settingsProvider = Provider<SettingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SettingsRepository(dio);
});

class SettingsRepository {
  final Dio _dio;

  SettingsRepository(this._dio);

  Future<void> sendSettingsOtp() async {
    try {
      final response = await _dio.post('/auth/send-settings-otp');
      if (response.data['success'] != true) {
        throw Exception('Failed to send OTP');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
      }
      throw Exception('Network error');
    }
  }

  Future<void> updateWithOtp({
    String? name,
    String? password,
    String? upiId,
    required String otp,
  }) async {
    final data = <String, dynamic>{'otp': otp};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (password != null && password.isNotEmpty) data['password'] = password;
    if (upiId != null && upiId.isNotEmpty) data['upiId'] = upiId;

    try {
      final response = await _dio.post('/auth/update-with-otp', data: data);
      if (response.data['success'] != true) {
        throw Exception('Failed to update settings');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Update failed');
      }
      throw Exception('Network error during update');
    }
  }

  Future<void> updateShop({
    String? name,
    String? gstin,
  }) async {
    final data = <String, dynamic>{};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (gstin != null) data['gstin'] = gstin.isNotEmpty ? gstin : null;

    if (data.isEmpty) return;

    try {
      final response = await _dio.patch('/shop', data: data);
      if (response.data['success'] != true) {
        throw Exception('Failed to update shop');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Update failed');
      }
      throw Exception('Network error');
    }
  }
}
