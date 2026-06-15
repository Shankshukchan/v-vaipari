import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/dio_client.dart';

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  late final Box _box;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _box = Hive.box('inventory');
    return await _fetchProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    List<Map<String, dynamic>> products = [];
    
    // 1. Load from offline cache first
    final cached = _box.get('products');
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      products = decoded.cast<Map<String, dynamic>>();
    }

    // 2. Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);
    
    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get('/inventory');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          products = rawList.cast<Map<String, dynamic>>();
          
          // Save to cache
          await _box.put('products', jsonEncode(products));
          
          await _syncOfflineQueue(dio);
        }
      } catch (e) {
        // Fallback to cached on error
      }
    }
    
    return products;
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }

  Future<void> _syncOfflineQueue(Dio dio) async {
    final queueBox = Hive.box('sync_queue');
    final keys = queueBox.keys.toList();
    
    bool needsRefresh = false;
    for (final key in keys) {
      final actionStr = queueBox.get(key) as String;
      final action = jsonDecode(actionStr);
      
      if (action['type'] == 'ADD_PRODUCT') {
        try {
          await dio.post('/inventory', data: action['payload']);
          await queueBox.delete(key);
          needsRefresh = true;
        } catch (e) {
          // Keep in queue if failed
        }
      } else if (action['type'] == 'UPDATE_PRODUCT') {
        try {
          final id = action['payload']['id'];
          final data = Map<String, dynamic>.from(action['payload'])..remove('id');
          await dio.patch('/inventory/$id', data: data);
          await queueBox.delete(key);
          needsRefresh = true;
        } catch (e) {
          // Keep in queue if failed
        }
      } else if (action['type'] == 'DELETE_PRODUCT') {
        try {
          final id = action['payload']['id'];
          await dio.delete('/inventory/$id');
          await queueBox.delete(key);
          needsRefresh = true;
        } catch (e) {
          // Keep in queue if failed
        }
      }
    }
    
    if (needsRefresh) {
      // Products were synced, fetch fresh list
      final response = await dio.get('/inventory');
      if (response.data['success'] == true) {
        final List<dynamic> rawList = response.data['data'];
        final products = rawList.cast<Map<String, dynamic>>();
        await _box.put('products', jsonEncode(products));
      }
    }
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    // Add locally immediately for offline-first experience
    final currentList = state.value ?? [];
    
    // We add a temporary ID for UI purposes
    final localProduct = {
      ...product,
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'stock': product['stock'] ?? 0,
      'lowStockAlert': product['lowStockAlert'] ?? 5,
    };
    
    final newList = [...currentList, localProduct];
    state = AsyncValue.data(newList);
    
    // Update local cache
    await _box.put('products', jsonEncode(newList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.post('/inventory', data: product);
        state = await AsyncValue.guard(() => _fetchProducts()); // Refresh IDs from server
      } catch (e) {
        _queueAction('ADD_PRODUCT', product);
      }
    } else {
      _queueAction('ADD_PRODUCT', product);
    }
  }

  void _queueAction(String type, Map<String, dynamic> payload) {
    final queueBox = Hive.box('sync_queue');
    queueBox.add(jsonEncode({
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    // Update locally first
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      final id = p['_id'] ?? p['id'];
      if (id == productId) return {...p, ...updates};
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put('products', jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.patch('/inventory/$productId', data: updates);
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        _queueAction('UPDATE_PRODUCT', {'id': productId, ...updates});
      }
    } else {
      _queueAction('UPDATE_PRODUCT', {'id': productId, ...updates});
    }
  }

  Future<void> deleteProduct(String productId) async {
    // Remove locally first
    final currentList = state.value ?? [];
    final updatedList = currentList.where((p) {
      final id = p['_id'] ?? p['id'];
      return id != productId;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _box.put('products', jsonEncode(updatedList));

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/inventory/$productId');
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        _queueAction('DELETE_PRODUCT', {'id': productId});
      }
    } else {
      _queueAction('DELETE_PRODUCT', {'id': productId});
    }
  }

  /// Find a product by barcode from the loaded list.
  /// Returns null if not found locally; optionally hits the API.
  Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    // First check local cache
    final products = state.value ?? [];
    final match = products.where((p) => p['barcode'] == barcode).toList();
    if (match.isNotEmpty) return match.first;

    // Try API lookup
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/inventory/barcode/$barcode');
      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Not found on server
    }
    return null;
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<Map<String, dynamic>>>(() {
  return InventoryNotifier();
});
