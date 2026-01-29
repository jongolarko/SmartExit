import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';

// Recommendation product model
class RecommendedProduct {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String? category;
  final String? description;
  final String? imageUrl;
  final int? stock;
  final double? confidence;
  final int? support;
  final double? score;

  RecommendedProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.category,
    this.description,
    this.imageUrl,
    this.stock,
    this.confidence,
    this.support,
    this.score,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      category: json['category'],
      description: json['description'],
      imageUrl: json['image_url'],
      stock: json['stock'],
      confidence: double.tryParse(json['confidence']?.toString() ?? '0'),
      support: json['support'],
      score: double.tryParse(json['score']?.toString() ?? '0'),
    );
  }
}

// Cart recommendations provider
// Fetches recommendations based on current cart contents
final cartRecommendationsProvider = FutureProvider.family<List<RecommendedProduct>, List<String>>(
  (ref, productIds) async {
    if (productIds.isEmpty) {
      return [];
    }

    final response = await ApiService.getCartRecommendations(
      productIds: productIds,
      limit: 5,
    );

    if (response['success'] == true) {
      return (response['recommendations'] as List?)
          ?.map((json) => RecommendedProduct.fromJson(json))
          .toList() ??
          [];
    }

    return [];
  },
);

// User recommendations provider
// Fetches personalized recommendations based on user history
final userRecommendationsProvider = FutureProvider<List<RecommendedProduct>>((ref) async {
  final response = await ApiService.getUserRecommendations(limit: 10);

  if (response['success'] == true) {
    return (response['recommendations'] as List?)
        ?.map((json) => RecommendedProduct.fromJson(json))
        .toList() ??
        [];
  }

  return [];
});

// Product recommendations provider
// Fetches recommendations for a specific product
final productRecommendationsProvider = FutureProvider.family<List<RecommendedProduct>, String>(
  (ref, productId) async {
    final response = await ApiService.getProductRecommendations(
      productId: productId,
      limit: 5,
    );

    if (response['success'] == true) {
      return (response['recommendations'] as List?)
          ?.map((json) => RecommendedProduct.fromJson(json))
          .toList() ??
          [];
    }

    return [];
  },
);
