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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Services',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText(context),
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                    'Find nearby services for your pet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.secondaryText(context),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.2, end: 0),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
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
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      title: 'Veterinarians',
                      subtitle: 'Clinics & animal hospitals',
                      icon: Icons.local_hospital_rounded,
                      tint: AppTheme.softBlush,
                      accent: AppTheme.accentRose,
                      serviceType: ServiceType.veterinarian,
                      delay: 100,
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      title: 'Grooming',
                      subtitle: 'Salons & grooming parlors',
                      icon: Icons.content_cut_rounded,
                      tint: AppTheme.softLavender,
                      accent: AppTheme.accentLavender,
                      serviceType: ServiceType.grooming,
                      delay: 200,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
        )
        .slideY(begin: 0.3, end: 0);
  }
}
