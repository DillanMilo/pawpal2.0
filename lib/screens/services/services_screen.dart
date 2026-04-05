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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Pet Services',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Find nearby services for your pet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
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
                      gradient: AppTheme.playfulGradient,
                      serviceType: ServiceType.petStore,
                      delay: 0,
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      title: 'Veterinarians',
                      subtitle: 'Clinics & animal hospitals',
                      icon: Icons.local_hospital_rounded,
                      gradient: AppTheme.sunsetGradient,
                      serviceType: ServiceType.veterinarian,
                      delay: 100,
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      context,
                      title: 'Grooming',
                      subtitle: 'Salons & grooming parlors',
                      icon: Icons.content_cut_rounded,
                      gradient: AppTheme.oceanGradient,
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
    required LinearGradient gradient,
    required ServiceType serviceType,
    required int delay,
  }) {
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: InkWell(
        onTap: () {
          context.push('/services/listing', extra: serviceType);
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
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
                color: Colors.white.withValues(alpha:0.2),
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
        .fadeIn(duration: 600.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.3, end: 0);
  }
}
