import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api', // Use 10.0.2.2 if on Android Emulator
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('🌐 API Request: ${options.method} ${options.baseUrl}${options.path}');
        print('📦 Data: ${options.data}');
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ API Error: ${e.message}');
        print('❌ URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        if (e.response != null) {
          print('❌ Status: ${e.response?.statusCode}');
          print('❌ Data: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
