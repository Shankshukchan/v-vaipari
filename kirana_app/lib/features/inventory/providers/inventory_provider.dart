import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/offline_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/token_utils.dart';

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await _fetchProducts();
  }

  Box get _box => Hive.box('inventory');

  Future<String?> _getShopId() => getShopIdFromToken();

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final shopId = await _getShopId();
    if (shopId == null) return [];

    final cached = getCachedList(_box, shopId, 'products');
    List<Map<String, dynamic>> products = List.from(cached);

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await ref.read(syncServiceProvider).processQueue(shopId: shopId);
        final response = await dio.get('/inventory');
        if (response.data['success'] == true) {
          final List<dynamic> rawList = response.data['data'];
          final serverList = rawList.cast<Map<String, dynamic>>();
          products = mergeLocalChanges(serverList, cached);
          await saveCachedList(_box, shopId, 'products', products);
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
    await saveCachedList(_box, shopId, 'products', newList);

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.post('/inventory', data: product);
        if (response.data['success'] != true) {
          throw Exception(response.data['message'] ?? 'Failed to add product');
        }
        // Replace temp entry with server-returned product
        final serverProduct = response.data['data'] as Map<String, dynamic>;
        final newList = [
          ...currentList.where((p) => p['id'] != localProduct['id']),
          serverProduct,
        ];
        state = AsyncValue.data(newList);
        await saveCachedList(_box, shopId, 'products', newList);
      } catch (e) {
        final cleaned = state.value?.where((p) => p['id'] != localProduct['id']).toList() ?? [];
        state = AsyncValue.data(cleaned);
        await saveCachedList(_box, shopId, 'products', cleaned);
        queueAction('ADD_PRODUCT', product, shopId);
        rethrow;
      }
    } else {
      queueAction('ADD_PRODUCT', product, shopId);
    }
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
    await saveCachedList(_box, shopId, 'products', updatedList);

    if (productId.startsWith('temp_')) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.patch('/inventory/$productId', data: updates);
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        queueAction('UPDATE_PRODUCT', {'id': productId, ...updates}, shopId);
      }
    } else {
      queueAction('UPDATE_PRODUCT', {'id': productId, ...updates}, shopId);
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
    await saveCachedList(_box, shopId, 'products', updatedList);

    if (productId.startsWith('temp_')) return;

    final isOnline = ref.read(isOnlineProvider);

    if (isOnline) {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete('/inventory/$productId');
        state = await AsyncValue.guard(() => _fetchProducts());
      } catch (e) {
        queueAction('DELETE_PRODUCT', {'id': productId}, shopId);
      }
    } else {
      queueAction('DELETE_PRODUCT', {'id': productId}, shopId);
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
