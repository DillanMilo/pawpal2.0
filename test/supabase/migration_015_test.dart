import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() {
    migration = File(
      'supabase/migrations/015_fix_quota_rls_and_daily_pawpoints.sql',
    ).readAsStringSync();
  });

  test('replaces recursive quota policies with security-definer counts', () {
    expect(migration, contains('SECURITY DEFINER'));
    expect(migration, contains('owned_medical_record_count(auth.uid())'));
    expect(migration, contains('active_reminder_count(user_id)'));
    expect(migration, contains('owned_pet_count(user_id)'));
  });

  test('enforces a race-safe, non-backdateable account-wide points cap', () {
    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains('NEW.created_at := statement_timestamp()'));
    expect(migration, contains('activity.user_id = NEW.user_id'));
    expect(migration, isNot(contains('activity.pet_id = NEW.pet_id')));
    expect(migration, contains('100 - earned_today'));
  });
}
