enum SubscriptionTier { free, plus }

enum SubscriptionStatus { trialing, active, canceled, pastDue, expired }

enum BillingSource { pawpalTrial, appStore, playStore, stripe, promotional }

class AccountEntitlement {
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final BillingSource source;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEndsAt;
  final String? productId;
  final String? store;
  final bool willRenew;

  const AccountEntitlement({
    required this.userId,
    required this.tier,
    required this.status,
    required this.source,
    this.trialStartedAt,
    this.trialEndsAt,
    this.currentPeriodEndsAt,
    this.productId,
    this.store,
    this.willRenew = false,
  });

  factory AccountEntitlement.fromJson(Map<String, dynamic> json) {
    return AccountEntitlement(
      userId: json['user_id'] as String,
      tier: _tierFromJson(json['tier'] as String?),
      status: _statusFromJson(json['status'] as String?),
      source: _sourceFromJson(json['source'] as String?),
      trialStartedAt: _dateFromJson(json['trial_started_at']),
      trialEndsAt: _dateFromJson(json['trial_ends_at']),
      currentPeriodEndsAt: _dateFromJson(json['current_period_ends_at']),
      productId: json['product_id'] as String?,
      store: json['store'] as String?,
      willRenew: json['will_renew'] as bool? ?? false,
    );
  }

  bool hasPlusAccessAt(DateTime now) {
    if (tier != SubscriptionTier.plus) return false;

    if (status == SubscriptionStatus.trialing) {
      return trialEndsAt?.isAfter(now) ?? false;
    }

    if (status == SubscriptionStatus.active ||
        status == SubscriptionStatus.canceled ||
        status == SubscriptionStatus.pastDue) {
      return currentPeriodEndsAt?.isAfter(now) ?? false;
    }

    return false;
  }

  bool get isTrial => status == SubscriptionStatus.trialing;

  static DateTime? _dateFromJson(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toLocal();
  }

  static SubscriptionTier _tierFromJson(String? value) {
    return value == 'plus' ? SubscriptionTier.plus : SubscriptionTier.free;
  }

  static SubscriptionStatus _statusFromJson(String? value) {
    return switch (value) {
      'trialing' => SubscriptionStatus.trialing,
      'active' => SubscriptionStatus.active,
      'canceled' => SubscriptionStatus.canceled,
      'past_due' => SubscriptionStatus.pastDue,
      _ => SubscriptionStatus.expired,
    };
  }

  static BillingSource _sourceFromJson(String? value) {
    return switch (value) {
      'app_store' => BillingSource.appStore,
      'play_store' => BillingSource.playStore,
      'stripe' => BillingSource.stripe,
      'promotional' => BillingSource.promotional,
      _ => BillingSource.pawpalTrial,
    };
  }
}

enum BillingPeriod { monthly, annual }

class PlanPrice {
  final BillingPeriod period;
  final String displayPrice;
  final String productId;

  const PlanPrice({
    required this.period,
    required this.displayPrice,
    required this.productId,
  });
}
