import 'dart:convert';
import 'package:hive/hive.dart';

String cacheKey(String shopId, String key) => '${shopId}_$key';

void queueAction(String type, Map<String, dynamic> payload, String shopId) {
  final queueBox = Hive.box('sync_queue');
  queueBox.add(jsonEncode({
    'type': type,
    'shopId': shopId,
    'payload': payload,
    'timestamp': DateTime.now().toIso8601String(),
    'retryCount': 0,
  }));
}

List<Map<String, dynamic>> getCachedList(Box box, String shopId, String prefix) {
  final cached = box.get(cacheKey(shopId, prefix));
  if (cached != null) {
    final List<dynamic> decoded = jsonDecode(cached);
    return decoded.cast<Map<String, dynamic>>();
  }
  return [];
}

Future<void> saveCachedList(Box box, String shopId, String prefix, List<Map<String, dynamic>> data) async {
  await box.put(cacheKey(shopId, prefix), jsonEncode(data));
}

List<Map<String, dynamic>> mergeLocalChanges(
  List<Map<String, dynamic>> serverData,
  List<Map<String, dynamic>> localData,
) {
  final merged = <Map<String, dynamic>>[];
  final serverIds = <String>{};

  for (final item in serverData) {
    final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
    if (id.isNotEmpty) serverIds.add(id);
    merged.add(item);
  }

  for (final item in localData) {
    final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
    if (id.startsWith('temp_')) {
      // Only keep temp entry if it hasn't been synced yet (no matching barcode on server)
      final barcode = item['barcode']?.toString();
      if (barcode != null && barcode.isNotEmpty) {
        final existsOnServer = serverData.any((s) => s['barcode']?.toString() == barcode);
        if (!existsOnServer) {
          merged.add(item);
        }
      } else {
        // No barcode to match against, keep it
        merged.add(item);
      }
    } else if (id.isNotEmpty && !serverIds.contains(id)) {
      merged.add(item);
    }
  }

  return merged;
}
