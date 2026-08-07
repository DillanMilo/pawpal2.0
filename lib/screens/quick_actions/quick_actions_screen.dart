import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/activity_icon.dart';
import '../../widgets/contextual_tip_card.dart';

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  bool _savingTip = false;

  Future<void> _dismissTip() async {
    setState(() => _savingTip = true);
    final saved = await context.read<AuthProvider>().completeQuickActionsTour();
    if (!mounted) return;
    setState(() => _savingTip = false);
    if (!saved) _showTipSaveError();
  }

  void _showTipSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('We couldn’t save that tip. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTip =
        context.watch<AuthProvider>().userProfile?.needsQuickActionsTour ==
        true;
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.borderFor(context),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryText(context),
            ),
          ),
        ),
        title: Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryText(context),
          ),
        ),
      ),
      body: QuickActionsContent(
        intro: showTip
            ? ContextualTipCard(
                title: 'Your pet-care shortcuts',
                description:
                    'Log everyday care, add medical details, scan a Pet Passport, or add another pet—all from this menu.',
                icon: Icons.pets_rounded,
                isSaving: _savingTip,
                onDismiss: _dismissTip,
              )
            : null,
        onActionSelected: (route) => context.go(route),
      ),
    );
  }
}

class QuickActionsSheet extends StatefulWidget {
  final ValueChanged<String> onActionSelected;

  const QuickActionsSheet({super.key, required this.onActionSelected});

  @override
  State<QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<QuickActionsSheet> {
  bool _isSelecting = false;
  bool _savingTip = false;

  void _handleActionSelected(String route) {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);
    widget.onActionSelected(route);
  }

  Future<void> _dismissTip() async {
    setState(() => _savingTip = true);
    final saved = await context.read<AuthProvider>().completeQuickActionsTour();
    if (!mounted) return;
    setState(() => _savingTip = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn’t save that tip. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = AppTheme.isDark(context);
    final showTip =
        context.watch<AuthProvider>().userProfile?.needsQuickActionsTour ==
        true;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.pageBackground(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: isDark
                  ? Border.all(color: AppTheme.darkDivider, width: 1.2)
                  : null,
              boxShadow: isDark ? [] : AppTheme.mediumShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.divider(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryText(context),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Flexible(
                    child: QuickActionsContent(
                      compact: true,
                      intro: showTip
                          ? ContextualTipCard(
                              title: 'Your pet-care shortcuts',
                              description:
                                  'Log everyday care, add medical details, scan a Pet Passport, or add another pet—all from this menu.',
                              icon: Icons.pets_rounded,
                              isSaving: _savingTip,
                              onDismiss: _dismissTip,
                            )
                          : null,
                      onActionSelected: _handleActionSelected,
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

class QuickActionsContent extends StatelessWidget {
  final ValueChanged<String> onActionSelected;
  final bool compact;
  final Widget? intro;

  const QuickActionsContent({
    super.key,
    required this.onActionSelected,
    this.compact = false,
    this.intro,
  });

  static final List<Map<String, dynamic>> _actionCards = [
    {
      'title': 'Medication',
      'subtitle': 'Track medications & doses',
      'type': 'Medication',
      'color': AppTheme.accentRose,
      'route': '/add-medication',
    },
    {
      'title': 'Vet Visit',
      'subtitle': 'Schedule & log vet appointments',
      'type': 'Vet Visit',
      'color': AppTheme.primaryColor,
      'route': '/add-vet-visit',
    },
    {
      'title': 'Grooming',
      'subtitle': 'Track grooming sessions',
      'type': 'Grooming',
      'color': AppTheme.accentPeach,
      'route': '/add-grooming',
    },
    {
      'title': 'Activity',
      'subtitle': 'Log activities with your pet',
      'type': 'Walk',
      'color': AppTheme.secondaryColor,
      'route': '/log-activity',
    },
    {
      'title': 'Scan Passport',
      'subtitle': 'Read a pet passport QR code',
      'type': 'Scan',
      'color': AppTheme.secondaryColor,
      'route': '/scan-passport',
    },
    {
      'title': 'Add New Pet',
      'subtitle': 'Add another furry friend',
      'type': 'Add',
      'color': AppTheme.accentLavender,
      'route': '/add-pet',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final subtitleColor = AppTheme.secondaryText(context);

    return Stack(
      children: [
        // Background decorative blobs
        if (!compact) ...[
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],

        // Main content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 24,
              vertical: compact ? 0 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (intro != null) ...[intro!, const SizedBox(height: 14)],
                if (!compact) ...[
                  Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),
                ],

                // Action cards list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: compact,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: compact ? 4 : 0),
                    itemCount: QuickActionsContent._actionCards.length,
                    itemBuilder: (context, index) {
                      final card = QuickActionsContent._actionCards[index];
                      final isAddPet = card['route'] == '/add-pet';

                      return _buildActionCard(
                            context: context,
                            title: card['title'],
                            subtitle: card['subtitle'],
                            type: card['type'],
                            color: card['color'],
                            isAddPet: isAddPet,
                            compact: compact,
                            onTap: () => onActionSelected(card['route']),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 150 * index),
                            duration: 500.ms,
                          )
                          .slideX(
                            begin: -0.3,
                            end: 0,
                            delay: Duration(milliseconds: 150 * index),
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String type,
    required Color color,
    required VoidCallback onTap,
    bool isAddPet = false,
    bool compact = false,
  }) {
    final isDark = AppTheme.isDark(context);
    final cardColor = isAddPet
        ? color.withValues(alpha: isDark ? 0.18 : 0.1)
        : AppTheme.cardBackground(context);
    final titleColor = isAddPet ? color : AppTheme.primaryText(context);
    final subtitleColor = AppTheme.secondaryText(context);

    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 10 : 16),
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(compact ? 22 : 28),
            border: isAddPet
                ? Border.all(color: color, width: 2.5)
                : AppTheme.borderFor(context),
            boxShadow: AppTheme.shadowFor(context),
          ),
          child: Row(
            children: [
              // Icon container
              ActivityIcon(
                type: type,
                size: compact ? 28 : 32,
                showBorder: false,
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: isDark ? 0.18 : (isAddPet ? 0.2 : 0.1),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAddPet ? Icons.add_rounded : Icons.arrow_forward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
