import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../services/places_service.dart';

class BusinessListingScreen extends StatefulWidget {
  final ServiceType serviceType;

  const BusinessListingScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<BusinessListingScreen> createState() => _BusinessListingScreenState();
}

class _BusinessListingScreenState extends State<BusinessListingScreen> {
  final TextEditingController _zipcodeController = TextEditingController();
  List<PlaceResult> _places = [];
  bool _isLoading = true;
  String? _error;
  bool _usingCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _zipcodeController.dispose();
    super.dispose();
  }

  String get _screenTitle {
    switch (widget.serviceType) {
      case ServiceType.petStore:
        return 'Pet Stores';
      case ServiceType.veterinarian:
        return 'Veterinarians';
      case ServiceType.grooming:
        return 'Grooming';
    }
  }

  IconData get _screenIcon {
    switch (widget.serviceType) {
      case ServiceType.petStore:
        return Icons.store_rounded;
      case ServiceType.veterinarian:
        return Icons.local_hospital_rounded;
      case ServiceType.grooming:
        return Icons.content_cut_rounded;
    }
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get current location
      final position = await PlacesService.getCurrentLocation();

      if (position != null) {
        _usingCurrentLocation = true;

        final places = await PlacesService.searchNearbyPlaces(
          type: widget.serviceType,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          _places = places;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _usingCurrentLocation = false;
          _error = 'Location access denied. Please enter your zipcode.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to fetch nearby places. Please try entering a zipcode.';
      });
    }
  }

  Future<void> _searchByZipcode() async {
    final zipcode = _zipcodeController.text.trim();
    if (zipcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a zipcode')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _usingCurrentLocation = false;
    });

    try {
      final places = await PlacesService.searchByZipcode(
        type: widget.serviceType,
        zipcode: zipcode,
      );

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not find places for that zipcode. Please try again.';
      });
    }
  }

  Future<void> _openDirections(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}&destination_place_id=${place.placeId}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> _callBusiness(PlaceResult place) async {
    if (place.phoneNumber == null) {
      // Try to get phone number from place details
      final details = await PlacesService.getPlaceDetails(place.placeId);
      if (details?.phoneNumber != null) {
        _launchPhone(details!.phoneNumber!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number not available')),
          );
        }
      }
    } else {
      _launchPhone(place.phoneNumber!);
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$cleanNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _screenIcon,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _screenTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Zipcode search
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _zipcodeController,
                            decoration: InputDecoration(
                              hintText: 'Enter zipcode...',
                              prefixIcon: const Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.textLight,
                              ),
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              hintStyle: const TextStyle(
                                color: AppTheme.textLight,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _searchByZipcode(),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Search by zipcode',
                          child: InkWell(
                            onTap: _searchByZipcode,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_usingCurrentLocation && !_isLoading && _error == null)
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          size: 14,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Using your current location',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Finding nearby $_screenTitle...',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 64,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _screenIcon,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No $_screenTitle found nearby',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching a different area',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return _buildBusinessCard(place, index);
      },
    );
  }

  Widget _buildBusinessCard(PlaceResult place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo header
          if (place.photoReference != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: place.photoUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: AppTheme.dividerColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  color: AppTheme.dividerColor,
                  child: Icon(
                    _screenIcon,
                    size: 48,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha:0.1),
                    AppTheme.secondaryColor.withValues(alpha:0.1),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Icon(
                  _screenIcon,
                  size: 48,
                  color: AppTheme.primaryColor.withValues(alpha:0.5),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and open status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (place.isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Rating
                if (place.rating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final rating = place.rating!;
                        if (i < rating.floor()) {
                          return const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppTheme.accentColor,
                          );
                        } else if (i < rating) {
                          return const Icon(
                            Icons.star_half_rounded,
                            size: 18,
                            color: AppTheme.accentColor,
                          );
                        } else {
                          return Icon(
                            Icons.star_outline_rounded,
                            size: 18,
                            color: AppTheme.textLight.withValues(alpha:0.5),
                          );
                        }
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${place.rating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (place.userRatingsTotal != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${place.userRatingsTotal} reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Get directions to ${place.name}',
                        child: InkWell(
                          onTap: () => _openDirections(place),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha:0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Directions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Call ${place.name}',
                        child: InkWell(
                          onTap: () => _callBusiness(place),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.secondaryColor,
                                width: 2,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  color: AppTheme.secondaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.2, end: 0);
  }
}
