import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Get the current user's shopId. Prefers the directly-stored value,
/// falls back to decoding the JWT.
Future<String?> getShopIdFromToken() async {
  final prefs = await SharedPreferences.getInstance();

  // Prefer the directly stored shop_id (set during login/register)
  final stored = prefs.getString('shop_id');
  if (stored != null && stored.isNotEmpty) return stored;

  // Fallback: decode from JWT
  final token = prefs.getString('auth_token');
  if (token == null || token.isEmpty) return null;

  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(parts[1]));
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final shopId = data['shopId'] as String?;
    if (shopId != null) {
      await prefs.setString('shop_id', shopId);
    }
    return shopId;
  } catch (_) {
    return null;
  }
}
