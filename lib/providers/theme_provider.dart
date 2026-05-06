import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PawPalThemePreference { light, dark, automatic }

class ThemeProvider extends ChangeNotifier {
  static const _preferenceKey = 'theme_preference';

  PawPalThemePreference _preference = PawPalThemePreference.light;
  Timer? _autoRefreshTimer;

  ThemeProvider() {
    _loadPreference();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_preference == PawPalThemePreference.automatic) {
        notifyListeners();
      }
    });
  }

  PawPalThemePreference get preference => _preference;

  ThemeMode get themeMode {
    return switch (_preference) {
      PawPalThemePreference.light => ThemeMode.light,
      PawPalThemePreference.dark => ThemeMode.dark,
      PawPalThemePreference.automatic =>
        _isDarkTime() ? ThemeMode.dark : ThemeMode.light,
    };
  }

  String get label {
    return switch (_preference) {
      PawPalThemePreference.light => 'Light',
      PawPalThemePreference.dark => 'Dark',
      PawPalThemePreference.automatic => 'Auto',
    };
  }

  Future<void> setPreference(PawPalThemePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, preference.name);
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_preferenceKey);
    PawPalThemePreference? savedPreference;
    for (final preference in PawPalThemePreference.values) {
      if (preference.name == savedValue) {
        savedPreference = preference;
        break;
      }
    }

    if (savedPreference == null) return;
    _preference = savedPreference;
    notifyListeners();
  }

  bool _isDarkTime() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
