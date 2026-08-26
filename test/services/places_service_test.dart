import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/services/places_service.dart';

void main() {
  setUpAll(() {
    // Initialize dotenv with test values for photoUrl test.
    dotenv.testLoad(
      fileInput: [
        'SUPABASE_URL=https://example.supabase.co',
        'SUPABASE_ANON_KEY=test_anon_key',
      ].join('\n'),
    );
  });

  group('PlaceResult.fromJson', () {
    test('parses complete Google Places JSON', () {
      final json = {
        'place_id': 'ChIJ_test123',
        'name': 'Happy Paws Vet',
        'vicinity': '123 Main St, Springfield',
        'rating': 4.5,
        'user_ratings_total': 120,
        'geometry': {
          'location': {'lat': 37.7749, 'lng': -122.4194},
        },
        'opening_hours': {'open_now': true},
        'photos': [
          {'photo_reference': 'photo_ref_abc123', 'width': 400},
        ],
      };

      final result = PlaceResult.fromJson(json);

      expect(result.placeId, 'ChIJ_test123');
      expect(result.name, 'Happy Paws Vet');
      expect(result.address, '123 Main St, Springfield');
      expect(result.rating, 4.5);
      expect(result.userRatingsTotal, 120);
      expect(result.latitude, 37.7749);
      expect(result.longitude, -122.4194);
      expect(result.isOpen, true);
      expect(result.photoReference, 'photo_ref_abc123');
    });

    test('handles missing optional fields', () {
      final json = {
        'place_id': 'ChIJ_test123',
        'name': 'Some Place',
        'vicinity': '456 Oak Ave',
        'geometry': {
          'location': {'lat': 40.0, 'lng': -74.0},
        },
      };

      final result = PlaceResult.fromJson(json);

      expect(result.placeId, 'ChIJ_test123');
      expect(result.name, 'Some Place');
      expect(result.rating, isNull);
      expect(result.userRatingsTotal, isNull);
      expect(result.isOpen, false);
      expect(result.photoReference, isNull);
    });

    test('defaults to empty string when place_id is null', () {
      final json = {
        'name': 'No ID Place',
        'vicinity': 'Somewhere',
        'geometry': {
          'location': {'lat': 0.0, 'lng': 0.0},
        },
      };

      final result = PlaceResult.fromJson(json);
      expect(result.placeId, '');
    });

    test('defaults to Unknown when name is null', () {
      final json = {
        'place_id': 'test',
        'vicinity': 'Somewhere',
        'geometry': {
          'location': {'lat': 0.0, 'lng': 0.0},
        },
      };

      final result = PlaceResult.fromJson(json);
      expect(result.name, 'Unknown');
    });

    test('uses formatted_address as fallback for address', () {
      final json = {
        'place_id': 'test',
        'name': 'Test Place',
        'formatted_address': '789 Elm St, Cityville, ST 12345',
        'geometry': {
          'location': {'lat': 0.0, 'lng': 0.0},
        },
      };

      final result = PlaceResult.fromJson(json);
      expect(result.address, '789 Elm St, Cityville, ST 12345');
    });

    test(
      'uses default address when both vicinity and formatted_address are missing',
      () {
        final json = {
          'place_id': 'test',
          'name': 'Test Place',
          'geometry': {
            'location': {'lat': 0.0, 'lng': 0.0},
          },
        };

        final result = PlaceResult.fromJson(json);
        expect(result.address, 'Address not available');
      },
    );

    test('defaults coordinates to 0.0 when geometry is missing', () {
      final json = {
        'place_id': 'test',
        'name': 'Test Place',
        'vicinity': 'Somewhere',
      };

      final result = PlaceResult.fromJson(json);
      expect(result.latitude, 0.0);
      expect(result.longitude, 0.0);
    });

    test('handles empty photos array', () {
      final json = {
        'place_id': 'test',
        'name': 'Test Place',
        'vicinity': 'Somewhere',
        'geometry': {
          'location': {'lat': 0.0, 'lng': 0.0},
        },
        'photos': [],
      };

      final result = PlaceResult.fromJson(json);
      expect(result.photoReference, isNull);
    });

    test('handles integer rating cast to double', () {
      final json = {
        'place_id': 'test',
        'name': 'Test',
        'vicinity': 'Here',
        'rating': 4,
        'geometry': {
          'location': {'lat': 0.0, 'lng': 0.0},
        },
      };

      final result = PlaceResult.fromJson(json);
      expect(result.rating, 4.0);
      expect(result.rating, isA<double>());
    });
  });

  group('PlaceResult.photoUrl', () {
    test('returns empty string when photoReference is null', () {
      final result = PlaceResult(
        placeId: 'test',
        name: 'Test',
        address: '123 St',
        latitude: 0,
        longitude: 0,
        photoReference: null,
      );

      expect(result.photoUrl, '');
    });

    test('constructs correct URL when photoReference is set', () {
      final result = PlaceResult(
        placeId: 'test',
        name: 'Test',
        address: '123 St',
        latitude: 0,
        longitude: 0,
        photoReference: 'abc123',
      );

      final url = result.photoUrl;
      expect(
        url,
        contains('example.supabase.co/functions/v1/places-proxy/photo'),
      );
      expect(url, contains('photo_reference=abc123'));
      expect(url, contains('maxwidth=400'));
    });
  });

  group('ServiceType enum', () {
    test('has exactly 4 values', () {
      expect(ServiceType.values, hasLength(4));
    });

    test('contains expected values', () {
      expect(ServiceType.values, contains(ServiceType.petStore));
      expect(ServiceType.values, contains(ServiceType.veterinarian));
      expect(ServiceType.values, contains(ServiceType.grooming));
      expect(ServiceType.values, contains(ServiceType.boarding));
    });
  });
}
