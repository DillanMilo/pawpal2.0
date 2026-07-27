import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/subscription_feature.dart';
import '../providers/subscription_provider.dart';
import '../utils/theme.dart';

class PremiumFeatureGate extends StatelessWidget {
  final SubscriptionFeature feature;
  final Widget child;

  const PremiumFeatureGate({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    if (subscription.isLoading && subscription.entitlement == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (subscription.canUse(feature)) return child;

    final definition = SubscriptionCatalog.definition(feature);
    return Scaffold(
      appBar: AppBar(title: const Text('PawPal Plus')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.primaryColor,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    definition.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    definition.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Included in Plus for ${subscription.priceForMonthly}/month or ${subscription.priceForAnnual}/year.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/pricing'),
                      child: const Text('View PawPal Plus'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Not now'),
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

Future<bool> showPremiumUpgradeDialog(
  BuildContext context,
  SubscriptionFeature feature,
) async {
  final definition = SubscriptionCatalog.definition(feature);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${definition.title} is a Plus feature'),
          content: Text(definition.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('View plans'),
            ),
          ],
        ),
      ) ??
      false;
}
