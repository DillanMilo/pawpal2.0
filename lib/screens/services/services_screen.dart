import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/theme.dart';
import '../../services/places_service.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return Center(
              child: SizedBox(
                width: viewport.maxWidth > 900 ? 900 : viewport.maxWidth,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                  children: [
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryText(context),
                          ),
                    ).animate().fadeIn(duration: 220.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Find nearby services for your pet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.secondaryText(context),
                      ),
                    ).animate().fadeIn(duration: 220.ms, delay: 40.ms),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useTabletGrid = constraints.maxWidth >= 680;
                        final cards = [
                          _buildServiceCard(
                            context,
                            title: 'Pet Stores',
                            subtitle: 'Food, toys, supplies & more',
                            icon: Icons.store_rounded,
                            tint: AppTheme.softMint,
                            accent: AppTheme.secondaryColor,
                            serviceType: ServiceType.petStore,
                            delay: 0,
                          ),
                          _buildServiceCard(
                            context,
                            title: 'Veterinarians',
                            subtitle: 'Clinics & animal hospitals',
                            icon: Icons.local_hospital_rounded,
                            tint: AppTheme.softBlush,
                            accent: AppTheme.accentRose,
                            serviceType: ServiceType.veterinarian,
                            delay: 40,
                          ),
                          _buildServiceCard(
                            context,
                            title: 'Grooming',
                            subtitle: 'Salons & grooming parlors',
                            icon: Icons.content_cut_rounded,
                            tint: AppTheme.softLavender,
                            accent: AppTheme.primaryColor,
                            serviceType: ServiceType.grooming,
                            delay: 80,
                          ),
                          _buildServiceCard(
                            context,
                            title: 'Boarding & Daycare',
                            subtitle: 'Kennels, pet hotels & daytime care',
                            icon: Icons.night_shelter_rounded,
                            tint: AppTheme.softMint,
                            accent: AppTheme.secondaryColor,
                            serviceType: ServiceType.boarding,
                            delay: 120,
                          ),
                        ];

                        if (!useTabletGrid) {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 16),
                              cards[1],
                              const SizedBox(height: 16),
                              cards[2],
                              const SizedBox(height: 16),
                              cards[3],
                            ],
                          );
                        }

                        final cardWidth = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final card in cards)
                              SizedBox(width: cardWidth, child: card),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tint,
    required Color accent,
    required ServiceType serviceType,
    required int delay,
  }) {
    final isDark = AppTheme.isDark(context);

    return Semantics(
          button: true,
          label: '$title: $subtitle',
          child: InkWell(
            onTap: () {
              context.push('/services/listing', extra: serviceType);
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground(context),
                borderRadius: BorderRadius.circular(24),
                border: AppTheme.borderFor(context),
                boxShadow: AppTheme.shadowFor(context),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? accent.withValues(alpha: 0.16) : tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accent, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.primaryText(context),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.secondaryText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primaryColor : AppTheme.inkColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 220.ms,
          delay: Duration(milliseconds: delay),
        )
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}
