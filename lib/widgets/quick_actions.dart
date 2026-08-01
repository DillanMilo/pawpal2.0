import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class QuickActions extends StatelessWidget {
  final Function(String) onActivitySelected;
  final Pet? selectedPet;

  const QuickActions({
    super.key,
    required this.onActivitySelected,
    this.selectedPet,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.activityTypes.length,
        itemBuilder: (context, index) {
          final type = AppConstants.activityTypes[index];
          return _ActionButton(
            type: type,
            onTap: selectedPet != null ? () => onActivitySelected(type) : null,
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String type;
  final VoidCallback? onTap;

  const _ActionButton({required this.type, this.onTap});

  IconData get _icon {
    switch (type) {
      case 'Walk':
        return Icons.directions_walk;
      case 'Play':
        return Icons.sports_baseball;
      case 'Train':
        return Icons.school;
      case 'Feed':
        return Icons.restaurant;
      case 'Groom':
        return Icons.content_cut;
      case 'Vet Visit':
        return Icons.local_hospital;
      case 'Social':
        return Icons.groups;
      case 'Rest':
        return Icons.bedtime;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.activityColors[type] ?? AppTheme.primaryColor;
    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      label: 'Log $type activity',
      enabled: isEnabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? color.withValues(alpha: 0.1)
                      : AppTheme.pageBackground(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEnabled ? color : AppTheme.divider(context),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _icon,
                  color: isEnabled ? color : AppTheme.mutedText(context),
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? AppTheme.primaryText(context)
                      : AppTheme.mutedText(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
