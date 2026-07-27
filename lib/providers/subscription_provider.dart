import 'package:flutter/foundation.dart';
import '../models/account_entitlement.dart';
import '../models/subscription_feature.dart';
import '../services/entitlement_service.dart';
import '../services/purchase_service.dart';
import '../utils/constants.dart';

class SubscriptionProvider with ChangeNotifier {
  final EntitlementService _entitlementService = EntitlementService();
  final RevenueCatPurchaseService _purchaseService =
      RevenueCatPurchaseService();

  String? _userId;
  AccountEntitlement? _entitlement;
  Map<BillingPeriod, PlanPrice> _planPrices = const {};
  bool _storeHasPlusAccess = false;
  bool _isLoading = false;
  bool _isPurchasing = false;
  String? _error;

  AccountEntitlement? get entitlement => _entitlement;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  bool get billingAvailable =>
      AppConstants.enableBilling &&
      _purchaseService.isConfigured &&
      _planPrices.isNotEmpty;
  bool get hasPlusAccess =>
      _storeHasPlusAccess ||
      (_entitlement?.hasPlusAccessAt(DateTime.now()) ?? false);

  bool canUse(SubscriptionFeature feature) => hasPlusAccess;
  String get priceForMonthly => priceFor(BillingPeriod.monthly);
  String get priceForAnnual => priceFor(BillingPeriod.annual);

  bool canAddPet(int currentPetCount) =>
      hasPlusAccess || currentPetCount < AppConstants.freePetLimit;
  bool canAddReminder(int activeReminderCount) =>
      hasPlusAccess ||
      activeReminderCount < AppConstants.freeActiveReminderLimit;
  bool canAddMedicalRecord(int currentRecordCount) =>
      hasPlusAccess || currentRecordCount < AppConstants.freeMedicalRecordLimit;
  bool get isTrialing =>
      _entitlement?.isTrial == true &&
      (_entitlement?.trialEndsAt?.isAfter(DateTime.now()) ?? false);
  DateTime? get trialEndsAt => _entitlement?.trialEndsAt;

  String priceFor(BillingPeriod period) {
    final remotePrice = _planPrices[period]?.displayPrice;
    if (remotePrice != null) return remotePrice;
    return period == BillingPeriod.monthly
        ? AppConstants.monthlyDisplayPrice
        : AppConstants.annualDisplayPrice;
  }

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;

    if (userId == null) {
      _entitlement = null;
      _planPrices = const {};
      _storeHasPlusAccess = false;
      _isLoading = false;
      _isPurchasing = false;
      _error = null;
      notifyListeners();
      return;
    }

    Future<void>.microtask(refresh);
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        _entitlement = await _entitlementService.getCurrentEntitlement();
      } catch (_) {
        // The app remains usable while migration 011 is being deployed.
        _entitlement = null;
      }

      final configured = await _purchaseService.initialize(userId);
      if (configured) {
        _planPrices = await _purchaseService.getPlanPrices();
        _storeHasPlusAccess = await _purchaseService.hasStoreEntitlement();
      }
    } catch (error) {
      _error = 'Subscription status is temporarily unavailable.';
      debugPrint('Subscription refresh failed: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchase(BillingPeriod period) async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    final outcome = await _purchaseService.purchase(period);
    _isPurchasing = false;
    _storeHasPlusAccess = outcome.hasPlusAccess;
    _error = outcome.wasCancelled ? null : outcome.error;
    notifyListeners();

    if (outcome.hasPlusAccess) {
      // The RevenueCat webhook is authoritative, but refresh opportunistically
      // so account screens converge as soon as the event reaches Supabase.
      Future<void>.delayed(const Duration(seconds: 2), refresh);
    }
    return outcome.hasPlusAccess;
  }

  Future<bool> restorePurchases() async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    final outcome = await _purchaseService.restore();
    _isPurchasing = false;
    _storeHasPlusAccess = outcome.hasPlusAccess;
    _error = outcome.error;
    notifyListeners();
    return outcome.hasPlusAccess;
  }
}
