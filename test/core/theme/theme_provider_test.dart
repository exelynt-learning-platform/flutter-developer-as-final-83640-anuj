import 'package:exelynt_learning/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('defaults to system theme when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      expect(provider.themeMode, ThemeMode.system);
      await Future<void>.delayed(Duration.zero);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('loads a previously persisted theme mode', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final provider = ThemeProvider();

      await Future<void>.delayed(Duration.zero);

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('setThemeMode updates state and persists the choice', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('toggleTheme switches between light and dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final provider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('notifies listeners when the theme changes', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.dark);

      expect(notified, isTrue);
    });
  });
}
