import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contextual tour migration stores both completion timestamps', () {
    final sql = File(
      'supabase/migrations/016_contextual_product_tours.sql',
    ).readAsStringSync();

    expect(sql, contains('quick_actions_tour_completed_at TIMESTAMPTZ'));
    expect(sql, contains('pet_profile_tour_completed_at TIMESTAMPTZ'));
    expect(sql, isNot(contains('UPDATE public.users')));
  });
}
