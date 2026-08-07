import 'package:flutter/material.dart';

import '../utils/theme.dart';

class ContextualTipCard extends StatelessWidget {
  const ContextualTipCard({
    super.key,
    required this.title,
    required this.description,
    required this.onDismiss,
    this.icon = Icons.lightbulb_rounded,
    this.isSaving = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSaving;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Semantics(
      container: true,
      label: '$title. $description',
      child: Container(
        key: const Key('contextual-tip-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: AppTheme.actionBlueGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('dismiss-contextual-tip'),
                      onPressed: isSaving ? null : onDismiss,
                      child: isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Got it'),
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
}
