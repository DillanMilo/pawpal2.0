import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pet.dart';
import '../utils/theme.dart';

class PetCarousel extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selectedPet;
  final Function(Pet) onPetSelected;
  final VoidCallback onAddPet;

  const PetCarousel({
    super.key,
    required this.pets,
    this.selectedPet,
    required this.onPetSelected,
    required this.onAddPet,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pets.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _AddPetCard(onTap: onAddPet);
          }
          final pet = pets[index];
          final isSelected = selectedPet?.id == pet.id;
          return _PetCard(
            pet: pet,
            isSelected: isSelected,
            onTap: () => onPetSelected(pet),
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetCard({
    required this.pet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;

    return Semantics(
      label: 'Select ${pet.name}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? categoryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pet photo
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: pet.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: pet.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: categoryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.pets,
                            color: categoryColor,
                            size: 30,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: categoryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.pets,
                            color: categoryColor,
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        color: categoryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.pets,
                          color: categoryColor,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Pet name
            Text(
              pet.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? categoryColor : AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Pet species
            Text(
              pet.species,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add a new pet',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.dividerColor,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Pet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
