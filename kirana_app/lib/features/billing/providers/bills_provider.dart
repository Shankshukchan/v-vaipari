import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/token_utils.dart';

class BillsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await _fetchBills();
  }

  Box get _box => Hive.box('bills');

  String _cacheKey(String shopId, String key) => '${shopId}_$key';

  Future<String?> _getShopId() => getShopIdFromToken();

  Future<List<Map<String, dynamic>>> _fetchBills() async {
    final shopId = await _getShopId();
    if (shopId == null) return [];

    List<Map<String, dynamic>> bills = [];

    final cached = _box.get(_cacheKey(shopId, 'bills'));
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      bills = decoded.cast<Map<String, dynamic>>();
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/bills');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          bills = rawList.cast<Map<String, dynamic>>();
          await _box.put(_cacheKey(shopId, 'bills'), jsonEncode(bills));
        }
      } catch (e) {
        // Fallback to cached
      }
    }

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

  Future<void> saveBill(Map<String, dynamic> bill) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final newList = [bill, ...currentList];
    state = AsyncValue.data(newList);
    await _box.put(_cacheKey(shopId, 'bills'), jsonEncode(newList));

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
          'customerName': bill['customerName'] ?? '',
          'customerPhone': bill['customerPhone'] ?? '',
          if (bill['customerId'] != null) 'customerId': bill['customerId'],
        });
        if (response.data['success'] == true) {
          final serverBill = response.data['data'] as Map<String, dynamic>;
          final idx = newList.indexWhere((b) => b['id'] == bill['id']);
          if (idx != -1) {
            newList[idx] = serverBill;
            state = AsyncValue.data(newList);
            await _box.put(_cacheKey(shopId, 'bills'), jsonEncode(newList));
          }
        }
      } catch (e) {
        // Keep local version
      }
    }
  }

  Future<void> deleteBill(String billId) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final updatedList = currentList.where((b) {
      final id = b['_id'] ?? b['id'];
      return id != billId;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put(_cacheKey(shopId, 'bills'), jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/bills/$billId');
        state = await AsyncValue.guard(() => _fetchBills());
      } catch (e) {
        state = await AsyncValue.guard(() => _fetchBills());
      }
    }
  }
}

final billsProvider = AsyncNotifierProvider<BillsNotifier, List<Map<String, dynamic>>>(() {
  return BillsNotifier();
});
