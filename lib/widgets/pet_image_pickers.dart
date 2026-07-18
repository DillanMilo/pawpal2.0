import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/theme.dart';

class PetAvatarPhotoPicker extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;
  final VoidCallback onTap;

  const PetAvatarPhotoPicker({
    super.key,
    required this.selectedPhoto,
    required this.existingPhotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Change pet profile photo',
        button: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dividerColor, width: 2),
            ),
            child: ClipOval(
              child: _PickedOrNetworkImage(
                selectedPhoto: selectedPhoto,
                existingPhotoUrl: existingPhotoUrl,
                placeholder: const _ImagePlaceholder(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PetCoverPhotoPicker extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;
  final VoidCallback onTap;

  const PetCoverPhotoPicker({
    super.key,
    required this.selectedPhoto,
    required this.existingPhotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Change pet card header photo',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 7,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground(context),
              borderRadius: BorderRadius.circular(22),
              border: AppTheme.borderFor(context),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PickedOrNetworkImage(
                  selectedPhoto: selectedPhoto,
                  existingPhotoUrl: existingPhotoUrl,
                  placeholder: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.homeHeroGradient,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.42),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Card Header Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Shown behind the pet profile picture',
                              style: TextStyle(
                                color: Color(0xFFDCD4F7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedOrNetworkImage extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;
  final Widget placeholder;

  const _PickedOrNetworkImage({
    required this.selectedPhoto,
    required this.existingPhotoUrl,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedPhoto;
    if (selected != null) {
      return FutureBuilder<Uint8List>(
        future: selected.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return placeholder;
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }

    final existing = existingPhotoUrl;
    if (existing != null && existing.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: existing,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      );
    }

    return placeholder;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImagePlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: AppTheme.textLight),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
      ],
    );
  }
}
