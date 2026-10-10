/// Single in-app purchase: "Buy Me a Coffee" ($0.99).
/// Product ID: qavexgomastercoffee
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService extends ChangeNotifier {
  static const String coffeeProductId = 'qavexgomastercoffee';
  static const String coffeeTitle = 'Buy Me a Coffee';
  static const String coffeePriceLabel = '\$0.99';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool storeAvailable = false;
  bool loading = true;
  String? error;
  ProductDetails? coffeeProduct;
  bool pendingPurchase = false;

  /// Called when the coffee purchase completes successfully.
  VoidCallback? onCoffeePurchased;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        error = e.toString();
        pendingPurchase = false;
        notifyListeners();
      },
    );
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final resp = await _iap.queryProductDetails({coffeeProductId});
        if (resp.productDetails.isNotEmpty) {
          coffeeProduct = resp.productDetails.first;
        } else {
          error = 'Product not found in the store yet.';
        }
        if (resp.error != null) error = resp.error!.message;
      } else {
        error = 'Store is not available on this device.';
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buyCoffee() async {
    final product = coffeeProduct;
    if (product == null || pendingPurchase) return;
    pendingPurchase = true;
    error = null;
    notifyListeners();
    try {
      // Coffee is a consumable-style one-time tip.
      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      error = e.toString();
      pendingPurchase = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      try {
        if (p.productID != coffeeProductId) {
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          continue;
        }
        switch (p.status) {
          case PurchaseStatus.pending:
            pendingPurchase = true;
            break;
          case PurchaseStatus.error:
            error = p.error?.message ?? 'Purchase failed.';
            pendingPurchase = false;
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            pendingPurchase = false;
            onCoffeePurchased?.call();
            break;
          case PurchaseStatus.canceled:
            pendingPurchase = false;
            break;
        }
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      } catch (e) {
        error = e.toString();
        pendingPurchase = false;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
