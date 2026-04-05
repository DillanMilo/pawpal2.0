import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../services/places_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Per-tab state
  final Map<ServiceType, List<PlaceResult>> _results = {};
  final Map<ServiceType, bool> _loading = {};
  final Map<ServiceType, String?> _errors = {};

  double? _latitude;
  double? _longitude;
  bool _locationDenied = false;
  bool _locationLoading = true;

  static const _tabs = [
    ServiceType.veterinarian,
    ServiceType.grooming,
    ServiceType.petStore,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final position = await PlacesService.getCurrentLocation();
    if (!mounted) return;

    if (position != null) {
      _latitude = position.latitude;
      _longitude = position.longitude;
      setState(() => _locationLoading = false);
      // Load all tabs
      for (final type in _tabs) {
        _loadPlaces(type);
      }
    } else {
      setState(() {
        _locationLoading = false;
        _locationDenied = true;
      });
    }
  }

  Future<void> _loadPlaces(ServiceType type) async {
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _loading[type] = true;
      _errors[type] = null;
    });

    try {
      final places = await PlacesService.searchNearbyPlaces(
        type: type,
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      setState(() {
        _results[type] = places;
        _loading[type] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading[type] = false;
        _errors[type] = 'Could not load results. Pull down to retry.';
      });
    }
  }

  Future<void> _searchByZipcode(ServiceType type, String zipcode) async {
    setState(() {
      _loading[type] = true;
      _errors[type] = null;
    });

    try {
      final places = await PlacesService.searchByZipcode(
        type: type,
        zipcode: zipcode,
      );
      if (!mounted) return;
      setState(() {
        _results[type] = places;
        _loading[type] = false;
        _locationDenied = false; // hide the zipcode prompt for this tab
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading[type] = false;
        _errors[type] = 'Could not find results for that zipcode.';
      });
    }
  }

  Future<void> _refreshTab(ServiceType type) async {
    if (_latitude != null && _longitude != null) {
      await _loadPlaces(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.local_hospital), text: 'Vets'),
            Tab(icon: Icon(Icons.content_cut), text: 'Groomers'),
            Tab(icon: Icon(Icons.store), text: 'Stores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(ServiceType.veterinarian),
          _buildTab(ServiceType.grooming),
          _buildTab(ServiceType.petStore),
        ],
      ),
    );
  }

  Widget _buildTab(ServiceType type) {
    // Still loading location
    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Location denied and no results yet for this tab
    if (_locationDenied && (_results[type] == null || _results[type]!.isEmpty)) {
      return _buildLocationDenied(type);
    }

    // Loading places
    if (_loading[type] == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Finding places nearby...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Error
    if (_errors[type] != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _errors[type]!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadPlaces(type),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showZipCodeDialog(type),
                icon: const Icon(Icons.search),
                label: const Text('Search by Zip Code'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty results
    final places = _results[type] ?? [];
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No places found nearby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try searching by zip code for a different area',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showZipCodeDialog(type),
                icon: const Icon(Icons.search),
                label: const Text('Search by Zip Code'),
              ),
            ],
          ),
        ),
      );
    }

    // Results list with pull-to-refresh
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => _refreshTab(type),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: places.length,
        itemBuilder: (context, index) {
          return _buildPlaceCard(places[index]);
        },
      ),
    );
  }

  Widget _buildLocationDenied(ServiceType type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Access Needed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enable location services to discover pet care providers nearby, or search by zip code.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _initLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text('Try Location Again'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showZipCodeDialog(type),
              icon: const Icon(Icons.search),
              label: const Text('Search by Zip Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(PlaceResult place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetails(place),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (place.photoReference != null)
              CachedNetworkImage(
                imageUrl: place.photoUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.storefront, size: 40, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + open badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (place.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Rating
                  if (place.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (place.userRatingsTotal != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${place.userRatingsTotal})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(PlaceResult place) {
    // Determine the ServiceType based on the current tab
    final tabIndex = _tabController.index;
    if (tabIndex < _tabs.length) {
      context.push('/services/listing', extra: _tabs[tabIndex]);
    }
  }

  Widget _buildComingSoon(String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction,
                size: 50,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$type Coming Soon',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'re working hard to bring you pet sitter discovery and booking features',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You\'ll be notified when this feature is available!'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Notify Me'),
            ),
          ],
        ),
      ),
    );
  }

  void _showZipCodeDialog([ServiceType? forType]) {
    final controller = TextEditingController();
    final type = forType ?? _tabs[_tabController.index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search by Zip Code'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter Zip Code',
            prefixIcon: Icon(Icons.location_searching),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.trim().isNotEmpty) {
              _searchByZipcode(type, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final zip = controller.text.trim();
              if (zip.isNotEmpty) {
                _searchByZipcode(type, zip);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
