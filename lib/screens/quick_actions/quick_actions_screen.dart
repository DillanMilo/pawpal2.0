import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/theme.dart';
import '../../widgets/activity_icon.dart';

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  final List<Map<String, dynamic>> _actionCards = [
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
      'title': 'Add New Pet',
      'subtitle': 'Add another furry friend',
      'type': 'Add',
      'color': AppTheme.accentLavender,
      'route': '/add-pet',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.thickBorder,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          ),
        ),
        title: const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decorative blobs
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.08),
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
                color: AppTheme.secondaryColor.withOpacity(0.08),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Action cards list
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _actionCards.length,
                      itemBuilder: (context, index) {
                        final card = _actionCards[index];
                        final isAddPet = card['route'] == '/add-pet';

                        return _buildActionCard(
                          title: card['title'],
                          subtitle: card['subtitle'],
                          type: card['type'],
                          color: card['color'],
                          isAddPet: isAddPet,
                          onTap: () => context.push(card['route']),
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
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String type,
    required Color color,
    required VoidCallback onTap,
    bool isAddPet = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isAddPet ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isAddPet
              ? Border.all(color: color, width: 2.5)
              : AppTheme.thickBorder,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon container
            ActivityIcon(
              type: type,
              size: 32,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isAddPet ? color : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(isAddPet ? 0.2 : 0.1),
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
    );
  }
}
