import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

enum ServiceType { petStore, veterinarian, grooming, boarding }

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? website;
  final String? googleMapsUri;
  final double? rating;
  final int? userRatingsTotal;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String? photoReference;
  final List<String>? openingHours;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.website,
    this.googleMapsUri,
    this.rating,
    this.userRatingsTotal,
    required this.latitude,
    required this.longitude,
    this.isOpen = false,
    this.photoReference,
    this.openingHours,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      address:
          json['vicinity'] ??
          json['formatted_address'] ??
          'Address not available',
      phoneNumber:
          json['formatted_phone_number'] ?? json['international_phone_number'],
      website: json['website'],
      googleMapsUri: json['url'],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      latitude: (geometry?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (geometry?['lng'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['opening_hours']?['open_now'] ?? false,
      photoReference: (json['photos'] as List?)?.isNotEmpty == true
          ? json['photos'][0]['photo_reference']
          : null,
    );
  }

  String get photoUrl {
    if (photoReference == null) return '';
    return '${AppConstants.supabaseUrl}/functions/v1/places-proxy/photo'
        '?maxwidth=400'
        '&photo_reference=${Uri.encodeQueryComponent(photoReference!)}';
  }
}

class PlacesService {
  static void _ensureConfigured() {
    if (AppConstants.supabaseUrl.isEmpty ||
        AppConstants.supabaseAnonKey.isEmpty) {
      throw Exception('Supabase is not configured.');
    }
  }

  static String _serviceTypeValue(ServiceType type) {
    switch (type) {
      case ServiceType.petStore:
        return 'petStore';
      case ServiceType.veterinarian:
        return 'veterinarian';
      case ServiceType.grooming:
        return 'grooming';
      case ServiceType.boarding:
        return 'boarding';
    }
  }

  static Future<Map<String, dynamic>> _invokePlacesProxy(
    Map<String, dynamic> body,
  ) async {
    _ensureConfigured();

    try {
      final response = await SupabaseService.client.functions.invoke(
        'places-proxy',
        body: body,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is String && data.isNotEmpty) {
        return json.decode(data) as Map<String, dynamic>;
      }

      throw Exception('Unexpected places response.');
    } catch (e) {
      throw Exception('Places request failed: $e');
    }
  }

  static List<PlaceResult> _placesFromResponse(Map<String, dynamic> data) {
    final results = data['results'] as List? ?? [];
    return results.map((place) => PlaceResult.fromJson(place)).toList();
  }

  /// Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Search for nearby places by service type
  static Future<List<PlaceResult>> searchNearbyPlaces({
    required ServiceType type,
    required double latitude,
    required double longitude,
    int radius = 10000, // 10km default radius
  }) async {
    final data = await _invokePlacesProxy({
      'action': 'nearby',
      'type': _serviceTypeValue(type),
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });

    return _placesFromResponse(data);
  }

  /// Search places by zipcode
  static Future<List<PlaceResult>> searchByZipcode({
    required ServiceType type,
    required String zipcode,
    int radius = 10000,
  }) async {
    return searchByLocationQuery(
      type: type,
      locationQuery: zipcode,
      radius: radius,
    );
  }

  /// Search places by postal code, city, region, or country.
  static Future<List<PlaceResult>> searchByLocationQuery({
    required ServiceType type,
    required String locationQuery,
    int radius = 10000,
  }) async {
    final trimmedQuery = locationQuery.trim();
    if (trimmedQuery.isEmpty) {
      throw Exception('Location query is empty.');
    }

    final data = await _invokePlacesProxy({
      'action': 'location',
      'type': _serviceTypeValue(type),
      'locationQuery': trimmedQuery,
      'radius': radius,
    });

    return _placesFromResponse(data);
  }

  /// Text Search fallback for broad international queries.
  static Future<List<PlaceResult>> searchByText({
    required ServiceType type,
    required String locationQuery,
  }) async {
    final data = await _invokePlacesProxy({
      'action': 'text',
      'type': _serviceTypeValue(type),
      'locationQuery': locationQuery,
    });

    return _placesFromResponse(data);
  }

  /// Get place details including phone number
  static Future<PlaceResult?> getPlaceDetails(String placeId) async {
    try {
      final data = await _invokePlacesProxy({
        'action': 'details',
        'placeId': placeId,
      });
      final result = data['result'];

      if (result != null) {
        final resultMap = Map<String, dynamic>.from(result as Map);
        final place = PlaceResult.fromJson(resultMap);
        return PlaceResult(
          placeId: place.placeId.isEmpty ? placeId : place.placeId,
          name: place.name,
          address: place.address,
          phoneNumber: place.phoneNumber,
          website: place.website,
          googleMapsUri: place.googleMapsUri,
          rating: place.rating,
          userRatingsTotal: place.userRatingsTotal,
          latitude: place.latitude,
          longitude: place.longitude,
          isOpen: place.isOpen,
          photoReference: place.photoReference,
          openingHours: (resultMap['opening_hours']?['weekday_text'] as List?)
              ?.map((e) => e.toString())
              .toList(),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
