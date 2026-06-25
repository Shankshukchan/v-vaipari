import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';

const int maxRetries = 5;

final syncServiceProvider = Provider<SyncService>((ref) {
  final dio = ref.read(dioProvider);
  return SyncService(dio);
});

class SyncService {
  final Dio _dio;
  SyncService(this._dio);

  Future<void> processQueue({required String shopId}) async {
    final queueBox = Hive.box('sync_queue');
    final keys = queueBox.keys.toList();

    final sorted = <MapEntry<dynamic, Map<String, dynamic>>>[];
    for (final key in keys) {
      final raw = queueBox.get(key);
      if (raw is! String) continue;
      final action = jsonDecode(raw) as Map<String, dynamic>;
      if (action['shopId'] != shopId) continue;
      sorted.add(MapEntry(key, action));
    }

    sorted.sort((a, b) {
      final aTs = a.value['timestamp'] as String? ?? '';
      final bTs = b.value['timestamp'] as String? ?? '';
      return aTs.compareTo(bTs);
    });

    for (final entry in sorted) {
      final key = entry.key;
      final action = entry.value;
      final type = action['type'] as String?;
      final retryCount = action['retryCount'] as int? ?? 0;

      if (type == null) {
        await queueBox.delete(key);
        continue;
      }

      if (retryCount >= maxRetries) {
        await queueBox.delete(key);
        continue;
      }

      try {
        await _executeAction(type, action['payload'] as Map<String, dynamic>? ?? {});
        await queueBox.delete(key);
      } catch (e) {
        action['retryCount'] = retryCount + 1;
        await queueBox.put(key, jsonEncode(action));
      }
    }

    return;
  }

  Future<void> _executeAction(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case 'ADD_PRODUCT':
        await _dio.post('/inventory', data: payload);
      case 'UPDATE_PRODUCT':
        final id = payload['id'];
        final data = Map<String, dynamic>.from(payload)..remove('id');
        await _dio.patch('/inventory/$id', data: data);
      case 'DELETE_PRODUCT':
        final id = payload['id'];
        await _dio.delete('/inventory/$id');

      case 'ADD_BILL':
        await _dio.post('/bills', data: payload);
      case 'DELETE_BILL':
        final id = payload['id'];
        await _dio.delete('/bills/$id');

      case 'ADD_CUSTOMER':
        await _dio.post('/customers', data: payload);
      case 'UPDATE_CUSTOMER':
        final id = payload['id'];
        final data = Map<String, dynamic>.from(payload)..remove('id');
        await _dio.patch('/customers/$id', data: data);
      case 'DELETE_CUSTOMER':
        final id = payload['id'];
        await _dio.delete('/customers/$id');
      case 'ADD_TRANSACTION':
        final customerId = payload['customerId'];
        final data = Map<String, dynamic>.from(payload)..remove('customerId');
        await _dio.post('/customers/$customerId/transactions', data: data);
    }
  }
}
