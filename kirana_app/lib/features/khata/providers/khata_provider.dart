import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/token_utils.dart';

// ─── Customers List Provider ─────────────────────────────────────────────────

class KhataNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await _fetchCustomers();
  }

  Box get _box => Hive.box('khata');

  Future<String?> _getShopId() => getShopIdFromToken();

  Future<List<Map<String, dynamic>>> _fetchCustomers() async {
    final shopId = await _getShopId();
    if (shopId == null) return [];

    final cached = getCachedList(_box, shopId, 'customers');
    List<Map<String, dynamic>> customers = List.from(cached);

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/customers');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          final serverList = rawList.cast<Map<String, dynamic>>();
          customers = mergeLocalChanges(serverList, cached);
          await saveCachedList(_box, shopId, 'customers', customers);
        }
      } catch (e) {
        // Fallback to cached
      }
    }

    return customers;
  }

  Future<void> fetchCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<void> addCustomer(Map<String, dynamic> customer) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.post('/customers', data: customer);
        if (response.data['success'] == true) {
          state = await AsyncValue.guard(() => _fetchCustomers());
          return;
        }
      } catch (e) {
        // Fall through
      }
    }

    final currentList = state.value ?? [];
    final localCustomer = {
      ...customer,
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'balance': customer['balance'] ?? 0,
    };
    final newList = [localCustomer, ...currentList];
    state = AsyncValue.data(newList);
    await saveCachedList(_box, shopId, 'customers', newList);

    if (!isOnline) {
      queueAction('ADD_CUSTOMER', customer, shopId);
    }
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final updatedList = currentList.map((c) {
      if (c['_id'] == customerId) return {...c, ...updates};
      return c;
    }).toList();
    state = AsyncValue.data(updatedList);
    await saveCachedList(_box, shopId, 'customers', updatedList);

    if (customerId.startsWith('temp_')) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.patch('/customers/$customerId', data: updates);
        state = await AsyncValue.guard(() => _fetchCustomers());
      } catch (e) {
        queueAction('UPDATE_CUSTOMER', {'id': customerId, ...updates}, shopId);
      }
    } else {
      queueAction('UPDATE_CUSTOMER', {'id': customerId, ...updates}, shopId);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final updatedList = currentList.where((c) => c['_id'] != customerId).toList();
    state = AsyncValue.data(updatedList);
    await saveCachedList(_box, shopId, 'customers', updatedList);

    if (customerId.startsWith('temp_')) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/customers/$customerId');
        state = await AsyncValue.guard(() => _fetchCustomers());
      } catch (e) {
        queueAction('DELETE_CUSTOMER', {'id': customerId}, shopId);
      }
    } else {
      queueAction('DELETE_CUSTOMER', {'id': customerId}, shopId);
    }
  }

  Future<void> addTransaction(
    String customerId, {
    required String type,
    required double amount,
    String? note,
  }) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.post('/customers/$customerId/transactions', data: {
          'type': type,
          'amount': amount,
          if (note != null) 'note': note,
        });
        state = await AsyncValue.guard(() => _fetchCustomers());
        return;
      } catch (e) {
        // Fall through
      }
    }

    // Update local balance
    final currentList = state.value ?? [];
    final updatedList = currentList.map((c) {
      if (c['_id'] == customerId) {
        final currentBalance = (c['balance'] as num?)?.toDouble() ?? 0;
        final newBalance =
            type == 'CREDIT' ? currentBalance + amount : currentBalance - amount;
        return {...c, 'balance': newBalance};
      }
      return c;
    }).toList();
    state = AsyncValue.data(updatedList);
    await saveCachedList(_box, shopId, 'customers', updatedList);

    if (!isOnline) {
      queueAction('ADD_TRANSACTION', {
        'customerId': customerId,
        'type': type,
        'amount': amount,
        if (note != null) 'note': note,
      }, shopId);
    }
  }
}

final khataProvider =
    AsyncNotifierProvider<KhataNotifier, List<Map<String, dynamic>>>(() {
  return KhataNotifier();
});

// ─── Outstanding Summary Provider ────────────────────────────────────────────

class OutstandingSummaryNotifier
    extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return await _fetchSummary();
  }

  Future<Map<String, dynamic>> _fetchSummary() async {
    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/customers/summary');
        if (response.data['success'] == true) {
          return Map<String, dynamic>.from(response.data['data']);
        }
      } catch (e) {
        // Fall through
      }
    }

    final customers = ref.read(khataProvider).value ?? [];
    final totalOutstanding =
        customers.fold<double>(0, (sum, c) => sum + ((c['balance'] as num?)?.toDouble() ?? 0));
    return {
      'totalOutstanding': totalOutstanding,
      'totalCustomers': customers.length,
      'customersWithDues':
          customers.where((c) => ((c['balance'] as num?)?.toDouble() ?? 0) > 0).length,
    };
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSummary());
  }
}

final outstandingSummaryProvider =
    AsyncNotifierProvider<OutstandingSummaryNotifier, Map<String, dynamic>>(
        () => OutstandingSummaryNotifier());

// ─── Customer Transactions Provider ──────────────────────────────────────────

final customerTransactionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  final isOnline = ref.read(isOnlineProvider);

  if (isOnline) {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/customers/$customerId');
      if (response.data['success'] == true) {
        final data = Map<String, dynamic>.from(response.data['data']);
        return (data['transactions'] as List<dynamic>?)
                ?.map((t) => Map<String, dynamic>.from(t))
                .toList() ??
            [];
      }
    } catch (e) {
      // Fall through
    }
  }
  return [];
});

// ─── Customer Bills Provider ─────────────────────────────────────────────────

final customerBillsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  final isOnline = ref.read(isOnlineProvider);

  if (isOnline) {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/customers/$customerId/bills');
      if (response.data['success'] == true) {
        return (response.data['data'] as List<dynamic>)
                .map((b) => Map<String, dynamic>.from(b))
                .toList() ??
            [];
      }
    } catch (e) {
      // Fall through
    }
  }
  return [];
});
