import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/token_utils.dart';
import '../../inventory/providers/inventory_provider.dart';

class BillsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await _fetchBills();
  }

  Box get _box => Hive.box('bills');

  Future<String?> _getShopId() => getShopIdFromToken();

  Future<List<Map<String, dynamic>>> _fetchBills() async {
    final shopId = await _getShopId();
    if (shopId == null) return [];

    final cached = getCachedList(_box, shopId, 'bills');
    List<Map<String, dynamic>> bills = List.from(cached);

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/bills');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          final serverList = rawList.cast<Map<String, dynamic>>();
          bills = mergeLocalChanges(serverList, cached);
          await saveCachedList(_box, shopId, 'bills', bills);
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
    final localId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final localBill = {...bill, 'id': localId};
    final newList = [localBill, ...currentList];
    state = AsyncValue.data(newList);
    await saveCachedList(_box, shopId, 'bills', newList);

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
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
          final idx = newList.indexWhere((b) => b['id'] == localId);
          if (idx != -1) {
            newList[idx] = serverBill;
            state = AsyncValue.data(newList);
            await saveCachedList(_box, shopId, 'bills', newList);
          }
          ref.read(inventoryProvider.notifier).fetchProducts();
          return;
        }
      } catch (e) {
        // Queue for later sync
      }
    }

    queueAction('ADD_BILL', bill, shopId);
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
    await saveCachedList(_box, shopId, 'bills', updatedList);

    if (billId.startsWith('temp_')) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/bills/$billId');
      } catch (e) {
        queueAction('DELETE_BILL', {'id': billId}, shopId);
      }
    } else {
      queueAction('DELETE_BILL', {'id': billId}, shopId);
    }
  }
}

final billsProvider = AsyncNotifierProvider<BillsNotifier, List<Map<String, dynamic>>>(() {
  return BillsNotifier();
});
