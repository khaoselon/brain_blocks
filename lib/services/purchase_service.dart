// lib/services/purchase_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
//import '../models/purchase_models.dart';

// アプリ内購入モデル
class PurchaseItem {
  final String id;
  final String title;
  final String description;
  final String price;
  final bool purchased;

  const PurchaseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.purchased = false,
  });

  PurchaseItem copyWith({bool? purchased}) {
    return PurchaseItem(
      id: id,
      title: title,
      description: description,
      price: price,
      purchased: purchased ?? this.purchased,
    );
  }
}

class PurchaseService {
  static PurchaseService? _instance;
  static PurchaseService get instance => _instance ??= PurchaseService._();
  PurchaseService._();

  bool _isInitialized = false;
  late WidgetRef _ref;

  // 商品ID定義
  static const String adFreeProductId = 'ad_free_premium';
  static const String hintsPackId = 'hints_pack_10';
  static const String themePackId = 'theme_pack_premium';

  // 利用可能商品リスト
  List<PurchaseItem> _availableProducts = [];
  List<PurchaseItem> get availableProducts => _availableProducts;

  /// 購入サービス初期化
  Future<void> initialize(WidgetRef ref) async {
    _ref = ref;

    try {
      if (kDebugMode) {
        print('購入サービス初期化開始');
      }

      // 実際のIAPプラグインを使用する場合の初期化
      // await InAppPurchase.instance.isAvailable();

      // テスト用の商品データ
      _availableProducts = [
        const PurchaseItem(
          id: adFreeProductId,
          title: '広告除去',
          description: 'すべての広告を除去して快適にプレイ',
          price: '¥370',
        ),
        const PurchaseItem(
          id: hintsPackId,
          title: 'ヒント10回パック',
          description: 'ヒントを10回使用できるパック',
          price: '¥120',
        ),
        const PurchaseItem(
          id: themePackId,
          title: 'プレミアムテーマ',
          description: '特別なカラーテーマを利用可能',
          price: '¥250',
        ),
      ];

      // 購入済み商品の復元
      await _restorePurchases();

      _isInitialized = true;

      if (kDebugMode) {
        print('購入サービス初期化完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('購入サービス初期化エラー: $e');
      }
      rethrow;
    }
  }

  /// 商品購入
  Future<bool> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      throw Exception('Purchase service not initialized');
    }

    try {
      if (kDebugMode) {
        print('商品購入開始: $productId');
      }

      // 実際のIAP処理をシミュレート
      await Future.delayed(const Duration(seconds: 2));

      // テスト環境では常に成功
      if (kDebugMode) {
        await _handlePurchaseSuccess(productId);
        return true;
      }

      // 本番環境では実際のIAP処理
      // final result = await InAppPurchase.instance.buyNonConsumable(
      //   purchaseParam: PurchaseParam(productDetails: productDetails),
      // );

      return false; // 実装時に適切な値を返す
    } catch (e) {
      if (kDebugMode) {
        print('購入エラー: $e');
      }
      return false;
    }
  }

  /// 購入成功処理
  Future<void> _handlePurchaseSuccess(String productId) async {
    switch (productId) {
      case adFreeProductId:
        _ref.read(appSettingsProvider.notifier).updateAdFree(true);
        break;
      case hintsPackId:
        // ヒント回数追加処理
        break;
      case themePackId:
        // テーマアンロック処理
        break;
    }

    // 商品リスト更新
    _availableProducts = _availableProducts.map((product) {
      if (product.id == productId) {
        return product.copyWith(purchased: true);
      }
      return product;
    }).toList();

    if (kDebugMode) {
      print('購入処理完了: $productId');
    }
  }

  /// 購入復元
  Future<void> _restorePurchases() async {
    try {
      if (kDebugMode) {
        print('購入復元開始');
      }

      // 設定から購入状態を読み込み
      final settings = _ref.read(appSettingsProvider);

      if (settings.adFree) {
        _availableProducts = _availableProducts.map((product) {
          if (product.id == adFreeProductId) {
            return product.copyWith(purchased: true);
          }
          return product;
        }).toList();
      }

      if (kDebugMode) {
        print('購入復元完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('購入復元エラー: $e');
      }
    }
  }

  /// 商品情報取得
  PurchaseItem? getProduct(String productId) {
    try {
      return _availableProducts.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// 購入済みチェック
  bool isPurchased(String productId) {
    final product = getProduct(productId);
    return product?.purchased ?? false;
  }

  /// リソース解放
  void dispose() {
    // IAPリスナーの解放等
  }
}

// プロバイダー
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService.instance;
});
