import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/dio_client.dart';

class BillsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  late final Box _box;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _box = Hive.box('bills');
    return await _fetchBills();
  }

  Future<List<Map<String, dynamic>>> _fetchBills() async {
    List<Map<String, dynamic>> bills = [];

    // Load from local cache first
    final cached = _box.get('bills');
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      bills = decoded.cast<Map<String, dynamic>>();
    }

    // Try syncing with server
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/bills');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          bills = rawList.cast<Map<String, dynamic>>();
          await _box.put('bills', jsonEncode(bills));
        }
      } catch (e) {
        // Fallback to cached
      }
    }

    // Sort by date descending
    bills.sort((a, b) {
      final aDate = a['createdAt'] as String? ?? '';
      final bDate = b['createdAt'] as String? ?? '';
      return bDate.compareTo(aDate);
    });

    return bills;
  }

  Future<void> fetchBills() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBills());
  }

  /// Save a bill locally, then try syncing to server.
  Future<void> saveBill(Map<String, dynamic> bill) async {
    // Save locally first
    final currentList = state.value ?? [];
    final newList = [bill, ...currentList];
    state = AsyncValue.data(newList);
    await _box.put('bills', jsonEncode(newList));

    // Try to sync to server
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.post('/bills', data: {
          'items': (bill['items'] as List).map((item) => {
            'productId': item['productId'],
            'qty': item['quantity'],
          }).toList(),
          'discount': bill['discount'] ?? 0,
          'paymentMode': bill['paymentMode'] ?? 'CASH',
        });
        if (response.data['success'] == true) {
          // Replace local bill with server version (has real _id)
          final serverBill = response.data['data'] as Map<String, dynamic>;
          final idx = newList.indexWhere((b) => b['id'] == bill['id']);
          if (idx != -1) {
            newList[idx] = serverBill;
            state = AsyncValue.data(newList);
            await _box.put('bills', jsonEncode(newList));
          }
        }
      } catch (e) {
        // Keep local version, will sync later
      }
    }
  }

  Future<void> deleteBill(String billId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.where((b) {
      final id = b['_id'] ?? b['id'];
      return id != billId;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put('bills', jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/bills/$billId');
      } catch (e) {
        // Already removed locally
      }
    }
  }
}

final billsProvider = AsyncNotifierProvider<BillsNotifier, List<Map<String, dynamic>>>(() {
  return BillsNotifier();
});
