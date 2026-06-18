import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/token_utils.dart';

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await _fetchProducts();
  }

  Box get _box => Hive.box('inventory');

  String _cacheKey(String shopId, String key) => '${shopId}_$key';

  Future<String?> _getShopId() => getShopIdFromToken();

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final shopId = await _getShopId();
    if (shopId == null) return [];

    List<Map<String, dynamic>> products = [];

    final cached = _box.get(_cacheKey(shopId, 'products'));
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      products = decoded.cast<Map<String, dynamic>>();
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await _syncOfflineQueue(dio, shopId);
        final response = await dio.get('/inventory');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          products = rawList.cast<Map<String, dynamic>>();
          await _box.put(_cacheKey(shopId, 'products'), jsonEncode(products));
        }
      } catch (e) {
        // Fallback to cached
      }
    }

    return products;
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }

  Future<void> _syncOfflineQueue(Dio dio, String shopId) async {
    final queueBox = Hive.box('sync_queue');
    final prefix = '${shopId}_';
    final keys = queueBox.keys.toList();

    bool needsRefresh = false;
    for (final key in keys) {
      final raw = queueBox.get(key);
      if (raw is! String) continue;
      final action = jsonDecode(raw);
      if (action['type'] == null || !(action['type'] as String).startsWith('ADD_PRODUCT') &&
          !(action['type'] as String).startsWith('UPDATE_PRODUCT') &&
          !(action['type'] as String).startsWith('DELETE_PRODUCT')) continue;

      // Check if this action belongs to this shop
      if (action['shopId'] != shopId) continue;

      final type = action['type'] as String;
      try {
        if (type == 'ADD_PRODUCT') {
          await dio.post('/inventory', data: action['payload']);
        } else if (type == 'UPDATE_PRODUCT') {
          final id = action['payload']['id'];
          final data = Map<String, dynamic>.from(action['payload'])..remove('id');
          await dio.patch('/inventory/$id', data: data);
        } else if (type == 'DELETE_PRODUCT') {
          final id = action['payload']['id'];
          await dio.delete('/inventory/$id');
        }
        await queueBox.delete(key);
        needsRefresh = true;
      } catch (e) {
        // Keep in queue
      }
    }

    if (needsRefresh) {
      final response = await dio.get('/inventory');
      if (response.data['success'] == true) {
        final List<dynamic> rawList = response.data['data'];
        final products = rawList.cast<Map<String, dynamic>>();
        await _box.put(_cacheKey(shopId, 'products'), jsonEncode(products));
      }
    }
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    final shopId = await _getShopId();
    if (shopId == null) throw Exception('Not logged in');

    final currentList = state.value ?? [];
    final localProduct = {
      ...product,
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'stock': product['stock'] ?? 0,
      'lowStockAlert': product['lowStockAlert'] ?? 5,
    };

    final newList = [...currentList, localProduct];
    state = AsyncValue.data(newList);
    await _box.put(_cacheKey(shopId, 'products'), jsonEncode(newList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.post('/inventory', data: product);
        if (response.data['success'] != true) {
          throw Exception(response.data['message'] ?? 'Failed to add product');
        }
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        // Remove the optimistic local product on failure
        final cleaned = state.value?.where((p) => p['id'] != localProduct['id']).toList() ?? [];
        state = AsyncValue.data(cleaned);
        await _box.put(_cacheKey(shopId, 'products'), jsonEncode(cleaned));
        _queueAction('ADD_PRODUCT', product, shopId);
        rethrow;
      }
    } else {
      _queueAction('ADD_PRODUCT', product, shopId);
    }
  }

  void _queueAction(String type, Map<String, dynamic> payload, String shopId) {
    final queueBox = Hive.box('sync_queue');
    queueBox.add(jsonEncode({
      'type': type,
      'shopId': shopId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      final id = p['_id'] ?? p['id'];
      if (id == productId) return {...p, ...updates};
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put(_cacheKey(shopId, 'products'), jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.patch('/inventory/$productId', data: updates);
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        _queueAction('UPDATE_PRODUCT', {'id': productId, ...updates}, shopId);
      }
    } else {
      _queueAction('UPDATE_PRODUCT', {'id': productId, ...updates}, shopId);
    }
  }

  Future<void> deleteProduct(String productId) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final currentList = state.value ?? [];
    final updatedList = currentList.where((p) {
      final id = p['_id'] ?? p['id'];
      return id != productId;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put(_cacheKey(shopId, 'products'), jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/inventory/$productId');
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        _queueAction('DELETE_PRODUCT', {'id': productId}, shopId);
      }
    } else {
      _queueAction('DELETE_PRODUCT', {'id': productId}, shopId);
    }
  }

  Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    final products = state.value ?? [];
    final match = products.where((p) => p['barcode'] == barcode).toList();
    if (match.isNotEmpty) return match.first;

    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/inventory/barcode/$barcode');
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<Map<String, dynamic>>>(() {
  return InventoryNotifier();
});
