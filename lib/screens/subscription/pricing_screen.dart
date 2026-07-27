import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/account_entitlement.dart';
import '../../models/subscription_feature.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/brand_mark.dart';

class PricingScreen extends StatefulWidget {
  final bool isOnboarding;

  const PricingScreen({super.key, this.isOnboarding = false});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.completePricingOnboarding();
    if (!mounted) return;

    if (success) {
      context.go('/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.error ?? 'We could not finish setup. Please try again.',
        ),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _choosePlan(BillingPeriod period) async {
    final subscription = context.read<SubscriptionProvider>();
    if (!subscription.billingAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your free trial is active. Payments will open after store setup is complete.',
          ),
        ),
      );
      return;
    }

    final purchased = await subscription.purchase(period);
    if (!mounted) return;
    if (purchased) {
      if (widget.isOnboarding) {
        await _completeOnboarding();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PawPal Plus is now active.')),
        );
      }
      return;
    }

    final error = subscription.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _restorePurchases() async {
    final subscription = context.read<SubscriptionProvider>();
    final restored = await subscription.restorePurchases();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Your PawPal Plus purchase was restored.'
              : subscription.error ?? 'No active purchase was found.',
        ),
        backgroundColor: restored ? AppTheme.successColor : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final user = auth.userProfile;
    final trialEnd =
        subscription.trialEndsAt ??
        user?.createdAt.add(const Duration(days: AppConstants.trialDays));

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: const Text('PawPal plans'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
                onPressed: () => context.pop(),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isOnboarding) ...[
                    const Center(child: BrandMark(size: 72)),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    widget.isOnboarding
                        ? 'Welcome to PawPal'
                        : 'Choose the care that fits',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 32,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your first ${AppConstants.trialDays} days include every Plus feature. No payment is required and you will not be charged automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _TrialStatusCard(
                    trialEnd: trialEnd,
                    hasPlusAccess: subscription.hasPlusAccess,
                    isTrialing: subscription.isTrialing,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _PlanCard(
                          title: 'Annual',
                          price: subscription.priceFor(BillingPeriod.annual),
                          cadence: 'per year',
                          detail: 'About \$2.50/month · save 50%',
                          badge: 'Best value',
                          selected: true,
                          isLoading: subscription.isPurchasing,
                          onPressed: () => _choosePlan(BillingPeriod.annual),
                        ),
                        _PlanCard(
                          title: 'Monthly',
                          price: subscription.priceFor(BillingPeriod.monthly),
                          cadence: 'per month',
                          detail: 'Flexible monthly billing',
                          isLoading: subscription.isPurchasing,
                          onPressed: () => _choosePlan(BillingPeriod.monthly),
                        ),
                      ];

                      if (constraints.maxWidth >= 620) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 16),
                            Expanded(child: cards[1]),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 14),
                          cards[1],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const _PlanComparison(),
                  const SizedBox(height: 22),
                  if (widget.isOnboarding)
                    OutlinedButton(
                      onPressed: auth.isLoading ? null : _completeOnboarding,
                      child: const Text('Continue with my free trial'),
                    ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: subscription.isPurchasing
                          ? null
                          : _restorePurchases,
                      child: const Text('Restore purchases'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'After the trial, your account returns to PawPal Base unless you subscribe. Existing records remain viewable and can be deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.mutedText(context),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrialStatusCard extends StatelessWidget {
  final DateTime? trialEnd;
  final bool hasPlusAccess;
  final bool isTrialing;

  const _TrialStatusCard({
    required this.trialEnd,
    required this.hasPlusAccess,
    required this.isTrialing,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = trialEnd?.difference(now);
    final trialActive =
        isTrialing || (trialEnd?.isAfter(now) == true && hasPlusAccess);
    final statusText = trialActive
        ? _remainingText(remaining)
        : hasPlusAccess
        ? 'Plus is active'
        : 'Trial ended';
    final endText = trialActive && trialEnd != null
        ? 'Ends ${DateFormat.yMMMMd().add_jm().format(trialEnd!)}'
        : hasPlusAccess
        ? 'Your premium features are unlocked.'
        : 'Choose a plan to restore Plus features.';

    return Semantics(
      label: '$statusText. $endText',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.homeHeroGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    endText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _remainingText(Duration? remaining) {
    if (remaining == null || remaining.isNegative) return 'Trial ended';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    if (days == 0) return '$hours hours left in Plus';
    return '$days days, $hours hours left in Plus';
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String cadence;
  final String detail;
  final String? badge;
  final bool selected;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.cadence,
    required this.detail,
    this.badge,
    this.selected = false,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.borderFor(context).top.color,
          width: selected ? 2 : 1.2,
        ),
        boxShadow: AppTheme.shadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 7,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: AppTheme.primaryText(context),
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                cadence,
                style: TextStyle(color: AppTheme.secondaryText(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: selected
                ? ElevatedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: Text(isLoading ? 'Please wait…' : 'Choose $title'),
                  )
                : OutlinedButton(
                    onPressed: isLoading ? null : onPressed,
                    child: Text('Choose $title'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanComparison extends StatelessWidget {
  const _PlanComparison();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const base = _FeatureColumn(
          title: 'PawPal Base',
          subtitle: 'Useful care essentials · always free',
          features: SubscriptionCatalog.baseHighlights,
        );
        const plus = _FeatureColumn(
          title: 'PawPal Plus',
          subtitle: 'Scale, automation, insights, and sharing',
          features: [],
          premium: true,
        );

        if (constraints.maxWidth >= 620) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: base),
              SizedBox(width: 16),
              Expanded(child: plus),
            ],
          );
        }
        return const Column(children: [base, SizedBox(height: 14), plus]);
      },
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> features;
  final bool premium;

  const _FeatureColumn({
    required this.title,
    required this.subtitle,
    required this.features,
    this.premium = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayFeatures = premium
        ? SubscriptionCatalog.premiumFeatures.map((item) => item.title)
        : features;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: premium
            ? AppTheme.softTint(context, AppTheme.secondaryColor)
            : AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: AppTheme.borderFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryText(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (final feature in displayFeatures)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    premium
                        ? Icons.workspace_premium_rounded
                        : Icons.check_circle_rounded,
                    color: premium
                        ? AppTheme.primaryColor
                        : AppTheme.successColor,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
