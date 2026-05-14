import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Minimal product info returned from a barcode lookup.
class ProductInfo {
  final String barcode;
  final String? name;
  final String? brand;
  final String? quantity; // e.g. "500 g", "1 l"

  const ProductInfo({
    required this.barcode,
    this.name,
    this.brand,
    this.quantity,
  });

  /// A human-friendly display name that prefers the API's `product_name`.
  /// Falls back to brand, then to the raw barcode when needed.
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (brand != null && brand!.trim().isNotEmpty) return brand!.trim();
    return barcode;
  }
}

/// Looks up products by barcode against the free Open Food Facts API.
/// No auth, no API key. Returns `null` when the product isn't in the DB or
/// the request fails (caller should fall back to raw barcode input).
class ProductLookupService {
  ProductLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://world.openfoodfacts.org/api/v2/product';

  Future<ProductInfo?> lookupByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    final uri = Uri.parse(
      '$_base/$barcode.json?fields=product_name,brands,quantity',
    );
    debugPrint('[ProductLookup] GET $uri');
    try {
      final resp = await _client
          .get(uri, headers: {'User-Agent': 'SmartShop/1.0 (Flutter)'})
          .timeout(const Duration(seconds: 6));
      debugPrint('[ProductLookup] status=${resp.statusCode}');
      debugPrint('[ProductLookup] body=${resp.body}');
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;

      // status == 1 means product found; 0 means not found.
      if (body['status'] != 1) {
        debugPrint('[ProductLookup] not found for barcode=$barcode');
        return null;
      }

      final product = body['product'];
      if (product is! Map<String, dynamic>) return null;

      final info = ProductInfo(
        barcode: barcode,
        name: _nonEmpty(product['product_name']),
        brand: _nonEmpty(product['brands']),
        quantity: _nonEmpty(product['quantity']),
      );
      debugPrint(
        '[ProductLookup] parsed -> barcode=${info.barcode}, '
        'name=${info.name}, brand=${info.brand}, quantity=${info.quantity}, '
        'displayName="${info.displayName}"',
      );
      return info;
    } catch (e, st) {
      debugPrint('[ProductLookup] error: $e');
      debugPrint('$st');
      return null;
    }
  }

  static String? _nonEmpty(dynamic v) {
    if (v is! String) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
