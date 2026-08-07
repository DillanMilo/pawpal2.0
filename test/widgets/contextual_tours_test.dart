import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/screens/quick_actions/quick_actions_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_provider.dart';

void main() {
  UserProfile profile({
    DateTime? quickActionsCompletedAt,
    DateTime? petProfileCompletedAt,
  }) {
    final now = DateTime(2026, 8, 7);
    return UserProfile(
      id: 'user-1',
      email: 'sam@example.com',
      onboardingCompletedAt: now,
      appTourCompletedAt: now,
      quickActionsTourCompletedAt: quickActionsCompletedAt,
      petProfileTourCompletedAt: petProfileCompletedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('Quick Actions tip appears once and dismisses durably', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(
          status: AuthStatus.authenticated,
          userProfile: profile(),
        ),
        child: MaterialApp(
          home: Scaffold(body: QuickActionsSheet(onActionSelected: (_) {})),
        ),
      ),
    );

    expect(find.text('Your pet-care shortcuts'), findsOneWidget);
    expect(find.textContaining('add another pet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dismiss-contextual-tip')));
    await tester.pumpAndSettle();

    expect(find.text('Your pet-care shortcuts'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('completed Quick Actions tip stays hidden', (tester) async {
    final now = DateTime(2026, 8, 7);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(
          status: AuthStatus.authenticated,
          userProfile: profile(quickActionsCompletedAt: now),
        ),
        child: MaterialApp(
          home: Scaffold(body: QuickActionsSheet(onActionSelected: (_) {})),
        ),
      ),
    );

    expect(find.text('Your pet-care shortcuts'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
