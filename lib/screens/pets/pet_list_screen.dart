import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../utils/theme.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PetProvider>().loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add a new pet',
            onPressed: () => context.push('/add-pet'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => petProvider.loadPets(),
        child: petProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : petProvider.pets.isEmpty
            ? _buildEmptyState()
            : _buildPetList(petProvider),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No pets yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first pet to get started with PawPal',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-pet'),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetList(PetProvider petProvider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: petProvider.pets.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        final success = await petProvider.reorderPets(oldIndex, newIndex);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(petProvider.error ?? 'Failed to reorder pets'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      itemBuilder: (context, index) {
        final pet = petProvider.pets[index];
        return _PetListItem(
          key: ValueKey(pet.id),
          pet: pet,
          index: index,
          onOpen: () => context.push('/pet/${pet.id}'),
        );
      },
    );
  }
}

class _PetListItem extends StatelessWidget {
  final Pet pet;
  final int index;
  final VoidCallback onOpen;

  const _PetListItem({
    super.key,
    required this.pet,
    required this.index,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;

    return Semantics(
      label:
          'Select ${pet.name}, ${pet.species}${pet.breed != null ? ', ${pet.breed}' : ''}',
      button: true,
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'pet-photo-${pet.id}',
                    child: Container(
                      width: 80,
                      height: 80,
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
                                placeholder: (context, url) =>
                                    _PetPhotoFallback(color: categoryColor),
                                errorWidget: (context, url, error) =>
                                    _PetPhotoFallback(color: categoryColor),
                              )
                            : _PetPhotoFallback(color: categoryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PetListCopy(pet: pet, color: categoryColor),
                  ),
                  Tooltip(
                    message: 'Reorder pet',
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: AppTheme.textLight,
                        ),
                      ),
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

class _PetListCopy extends StatelessWidget {
  final Pet pet;
  final Color color;

  const _PetListCopy({required this.pet, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pet.species,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (pet.breed != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  pet.breed!,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.cake_outlined, size: 14, color: AppTheme.textLight),
            const SizedBox(width: 4),
            Text(
              pet.ageDisplay,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 16),
            Icon(
              pet.gender == 'Male'
                  ? Icons.male
                  : pet.gender == 'Female'
                  ? Icons.female
                  : Icons.transgender,
              size: 14,
              color: AppTheme.textLight,
            ),
            const SizedBox(width: 4),
            Text(
              pet.gender,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _PetPhotoFallback extends StatelessWidget {
  final Color color;

  const _PetPhotoFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Icon(Icons.pets, color: color, size: 40),
    );
  }
}
