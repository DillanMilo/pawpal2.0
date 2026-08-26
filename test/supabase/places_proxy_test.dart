import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'supabase/functions/places-proxy/index.ts',
    ).readAsStringSync();
  });

  test('accepts boarding as a service type', () {
    expect(source, contains("'grooming' | 'boarding'"));
    expect(source, contains("case 'boarding':"));
    expect(source, contains('pet boarding kennel pet hotel dog daycare'));
  });

  test('does not classify grooming searches as pet stores', () {
    final groomingTypeCase = RegExp(
      r"case 'grooming':\s+return null;",
      multiLine: true,
    );
    expect(source, matches(groomingTypeCase));
    expect(source, contains("type === 'grooming' || type === 'boarding'"));
    expect(
      source,
      contains("url.searchParams.set('query', getSearchQuery(type))"),
    );
  });
}
