import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

enum ServiceType {
  petStore,
  veterinarian,
  grooming,
}

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final String? phoneNumber;
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
      address: json['vicinity'] ?? json['formatted_address'] ?? 'Address not available',
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
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoReference'
        '&key=${AppConstants.googlePlacesApiKey}';
  }
}

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static String _getSearchQuery(ServiceType type) {
    switch (type) {
      case ServiceType.petStore:
        return 'pet store';
      case ServiceType.veterinarian:
        return 'veterinarian';
      case ServiceType.grooming:
        return 'pet grooming';
    }
  }

  static String _getPlaceType(ServiceType type) {
    switch (type) {
      case ServiceType.petStore:
        return 'pet_store';
      case ServiceType.veterinarian:
        return 'veterinary_care';
      case ServiceType.grooming:
        return 'pet_store'; // Google doesn't have a specific grooming type
    }
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
    final query = _getSearchQuery(type);
    final placeType = _getPlaceType(type);

    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json'
      '?location=$latitude,$longitude'
      '&radius=$radius'
      '&type=$placeType'
      '&keyword=$query'
      '&key=${AppConstants.googlePlacesApiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        return results
            .map((place) => PlaceResult.fromJson(place))
            .toList();
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching places: $e');
    }
  }

  /// Search places by zipcode
  static Future<List<PlaceResult>> searchByZipcode({
    required ServiceType type,
    required String zipcode,
    int radius = 10000,
  }) async {
    // First, geocode the zipcode to get coordinates
    final geocodeUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=$zipcode'
      '&key=${AppConstants.googlePlacesApiKey}',
    );

    try {
      final geocodeResponse = await http.get(geocodeUrl);

      if (geocodeResponse.statusCode == 200) {
        final geocodeData = json.decode(geocodeResponse.body);
        final results = geocodeData['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;

          return searchNearbyPlaces(
            type: type,
            latitude: lat,
            longitude: lng,
            radius: radius,
          );
        }
      }

      throw Exception('Could not find location for zipcode: $zipcode');
    } catch (e) {
      throw Exception('Error searching by zipcode: $e');
    }
  }

  /// Get place details including phone number
  static Future<PlaceResult?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json'
      '?place_id=$placeId'
      '&fields=place_id,name,formatted_address,formatted_phone_number,rating,user_ratings_total,geometry,opening_hours,photos'
      '&key=${AppConstants.googlePlacesApiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        if (result != null) {
          final geometry = result['geometry']?['location'];
          return PlaceResult(
            placeId: result['place_id'] ?? placeId,
            name: result['name'] ?? 'Unknown',
            address: result['formatted_address'] ?? 'Address not available',
            phoneNumber: result['formatted_phone_number'],
            rating: (result['rating'] as num?)?.toDouble(),
            userRatingsTotal: result['user_ratings_total'] as int?,
            latitude: (geometry?['lat'] as num?)?.toDouble() ?? 0.0,
            longitude: (geometry?['lng'] as num?)?.toDouble() ?? 0.0,
            isOpen: result['opening_hours']?['open_now'] ?? false,
            photoReference: (result['photos'] as List?)?.isNotEmpty == true
                ? result['photos'][0]['photo_reference']
                : null,
            openingHours: (result['opening_hours']?['weekday_text'] as List?)
                ?.map((e) => e.toString())
                .toList(),
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
