import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> login(String phone, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['success'] == true) {
        await _saveToken(response.data['data']['token']);
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

  Future<void> register(String name, String phone, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        'password': password,
      });

      if (response.data['success'] == true) {
        await _saveToken(response.data['data']['token']);
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

  Future<void> sendOtp(String email) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {'email': email});
      if (response.data['success'] != true) {
        throw Exception('Failed to send OTP');
      }
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
        await _saveToken(response.data['data']['token']);
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

  Future<void> googleAuth(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {'idToken': idToken});
      if (response.data['success'] == true) {
        await _saveToken(response.data['data']['token']);
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
