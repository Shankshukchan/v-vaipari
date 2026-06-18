import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> _saveToken(String token, {String? shopId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (shopId != null && shopId.isNotEmpty) {
      await prefs.setString('shop_id', shopId);
    }
  }

  /// Clear cache for the current user only (before token swap).
  Future<void> _clearCurrentUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = utf8.decode(base64Url.decode(parts[1]));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final shopId = data['shopId'] as String?;
      if (shopId == null) return;
      final inventoryBox = Hive.box('inventory');
      final billsBox = Hive.box('bills');
      final khataBox = Hive.box('khata');
      final syncBox = Hive.box('sync_queue');
      // Remove keys belonging to this shop
      for (final key in inventoryBox.keys.toList()) {
        if (key is String && key.startsWith('${shopId}_')) {
          await inventoryBox.delete(key);
        }
      }
      for (final key in billsBox.keys.toList()) {
        if (key is String && key.startsWith('${shopId}_')) {
          await billsBox.delete(key);
        }
      }
      for (final key in khataBox.keys.toList()) {
        if (key is String && key.startsWith('${shopId}_')) {
          await khataBox.delete(key);
        }
      }
      for (final key in syncBox.keys.toList()) {
        final raw = syncBox.get(key);
        if (raw is String) {
          try {
            final action = jsonDecode(raw);
            if (action['shopId'] == shopId) await syncBox.delete(key);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  String? _extractShopId(dynamic data) {
    if (data == null) return null;
    final user = data['user'];
    if (user == null) return null;
    return user['shopId'] as String? ?? (user['shopId']?['_id'] as String?);
  }

  Future<void> login(String phone, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token'], shopId: _extractShopId(data));
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      print('API Error [login]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error during login');
    } catch (e) {
      print('Unknown Error [login]: $e');
      rethrow;
    }
  }

  /// Returns true if email already exists in database
  Future<bool> checkEmail(String email) async {
    try {
      final response = await _dio.post('/auth/check-email', data: {'email': email});
      if (response.data['success'] == true) {
        return response.data['data']['emailExists'] as bool;
      }
      throw Exception('Failed to check email');
    } on DioException catch (e) {
      print('API Error [checkEmail]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to check email');
      }
      throw Exception('Network error while checking email');
    } catch (e) {
      print('Unknown Error [checkEmail]: $e');
      rethrow;
    }
  }

  /// Send OTP to email. Returns emailExists flag from server.
  Future<bool> sendOtp(String email) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {'email': email});
      if (response.data['success'] == true) {
        return response.data['data']['emailExists'] as bool? ?? false;
      }
      throw Exception('Failed to send OTP');
    } on DioException catch (e) {
      print('API Error [sendOtp]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    } catch (e) {
      print('Unknown Error [sendOtp]: $e');
      rethrow;
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token'], shopId: _extractShopId(data));
      } else {
        throw Exception('OTP Verification failed');
      }
    } on DioException catch (e) {
      print('API Error [verifyOtp]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'OTP Verification failed');
    } catch (e) {
      print('Unknown Error [verifyOtp]: $e');
      rethrow;
    }
  }

  /// Register with email, password, shop name, and optional GST.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? gstin,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'shopName': shopName,
        'gstin': gstin,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token'], shopId: _extractShopId(data));
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      print('API Error [register]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Network error during registration');
    } catch (e) {
      print('Unknown Error [register]: $e');
      rethrow;
    }
  }

  Future<void> googleAuth(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {'idToken': idToken});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token'], shopId: _extractShopId(data));
      } else {
        throw Exception('Google Auth failed');
      }
    } on DioException catch (e) {
      print('API Error [googleAuth]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Google Auth failed');
    } catch (e) {
      print('Unknown Error [googleAuth]: $e');
      rethrow;
    }
  }

  /// Fetch current user profile with populated shop data.
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch user profile');
    } on DioException catch (e) {
      print('API Error [getCurrentUser]: $e');
      if (e.response != null) print('Response data: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch user profile');
    } catch (e) {
      print('Unknown Error [getCurrentUser]: $e');
      rethrow;
    }
  }

  Future<void> logoutCurrentUserCache() async {
    await _clearCurrentUserCache();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('shop_id');
  }
}
