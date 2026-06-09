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

  Future<void> updateProfile({String? name, String? password}) async {
    final data = <String, dynamic>{};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (password != null && password.isNotEmpty) data['password'] = password;

    if (data.isEmpty) return;

    try {
      final response = await _dio.patch('/auth/me', data: data);
      if (response.data['success'] != true) {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Update failed');
      }
      throw Exception('Network error during update');
    } catch (e) {
      throw Exception('Update error: $e');
    }
  }
}
