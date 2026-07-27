import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as revenuecat;
import '../models/account_entitlement.dart';
import '../utils/constants.dart';

class PurchaseOutcome {
  final bool hasPlusAccess;
  final bool wasCancelled;
  final String? error;

  const PurchaseOutcome({
    required this.hasPlusAccess,
    this.wasCancelled = false,
    this.error,
  });
}

class RevenueCatPurchaseService {
  String? _configuredUserId;
  bool _configured = false;
  final Map<BillingPeriod, revenuecat.Package> _packages = {};

  bool get isConfigured => _configured;

  Future<bool> initialize(String userId) async {
    if (!AppConstants.enableBilling ||
        AppConstants.revenueCatApiKey.isEmpty ||
        !_isSupportedPlatform) {
      return false;
    }

    if (_configured) {
      if (_configuredUserId != userId) {
        await revenuecat.Purchases.logIn(userId);
        _configuredUserId = userId;
      }
      return true;
    }

    if (kDebugMode) {
      await revenuecat.Purchases.setLogLevel(revenuecat.LogLevel.debug);
    }
    final configuration = revenuecat.PurchasesConfiguration(
      AppConstants.revenueCatApiKey,
    )..appUserID = userId;
    await revenuecat.Purchases.configure(configuration);
    _configured = true;
    _configuredUserId = userId;
    return true;
  }

  Future<Map<BillingPeriod, PlanPrice>> getPlanPrices() async {
    if (!_configured) return const {};

    final offerings = await revenuecat.Purchases.getOfferings();
    final offering =
        offerings.getOffering(AppConstants.plusOfferingId) ?? offerings.current;
    if (offering == null) return const {};

    _packages.clear();
    final prices = <BillingPeriod, PlanPrice>{};
    final monthly = offering.monthly;
    final annual = offering.annual;

    if (monthly != null) {
      _packages[BillingPeriod.monthly] = monthly;
      prices[BillingPeriod.monthly] = PlanPrice(
        period: BillingPeriod.monthly,
        displayPrice: monthly.storeProduct.priceString,
        productId: monthly.storeProduct.identifier,
      );
    }
    if (annual != null) {
      _packages[BillingPeriod.annual] = annual;
      prices[BillingPeriod.annual] = PlanPrice(
        period: BillingPeriod.annual,
        displayPrice: annual.storeProduct.priceString,
        productId: annual.storeProduct.identifier,
      );
    }

    return prices;
  }

  Future<bool> hasStoreEntitlement() async {
    if (!_configured) return false;
    final customerInfo = await revenuecat.Purchases.getCustomerInfo();
    return customerInfo
            .entitlements
            .all[AppConstants.plusEntitlementId]
            ?.isActive ??
        false;
  }

  Future<PurchaseOutcome> purchase(BillingPeriod period) async {
    final package = _packages[period];
    if (!_configured || package == null) {
      return const PurchaseOutcome(
        hasPlusAccess: false,
        error: 'This subscription is not available yet.',
      );
    }

    try {
      final result = await revenuecat.Purchases.purchase(
        revenuecat.PurchaseParams.package(package),
      );
      final isActive =
          result
              .customerInfo
              .entitlements
              .all[AppConstants.plusEntitlementId]
              ?.isActive ??
          false;
      return PurchaseOutcome(hasPlusAccess: isActive);
    } on PlatformException catch (error) {
      final code = revenuecat.PurchasesErrorHelper.getErrorCode(error);
      if (code == revenuecat.PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome(hasPlusAccess: false, wasCancelled: true);
      }
      return PurchaseOutcome(
        hasPlusAccess: false,
        error: error.message ?? 'The purchase could not be completed.',
      );
    }
  }

  Future<PurchaseOutcome> restore() async {
    if (!_configured || kIsWeb) {
      return const PurchaseOutcome(
        hasPlusAccess: false,
        error: 'Purchase restoration is not available on this platform.',
      );
    }

    try {
      final customerInfo = await revenuecat.Purchases.restorePurchases();
      final isActive =
          customerInfo
              .entitlements
              .all[AppConstants.plusEntitlementId]
              ?.isActive ??
          false;
      return PurchaseOutcome(hasPlusAccess: isActive);
    } on PlatformException catch (error) {
      return PurchaseOutcome(
        hasPlusAccess: false,
        error: error.message ?? 'Purchases could not be restored.',
      );
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
