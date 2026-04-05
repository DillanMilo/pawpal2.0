import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'fake_auth_provider.dart';

/// Wraps a widget in MaterialApp + providers needed for testing.
/// Uses FakeAuthProvider so Supabase is never called.
Widget createTestWidget(Widget child) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>(
      create: (_) => FakeAuthProvider(),
      child: child,
    ),
  );
}
