import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode';
  static const _kSeedColor = 'settings.seedColor';
  static const _kLocale = 'settings.locale';

  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = const Color(0xFF2E7D32); // green — matches AppColors.primary
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  Locale get locale => _locale;

  /// Optional: expose a small list of preset seed colors in the UI.
  static const List<Color> presetColors = [
    Color(0xFF2E7D32), // green
    Color(0xFF1565C0), // blue
    Color(0xFF6A1B9A), // purple
    Color(0xFFC62828), // red
    Color(0xFFEF6C00), // orange
    Color(0xFF00838F), // teal
    Color(0xFF37474F), // blue grey
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_kThemeMode);
    if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    if (themeStr == 'system') _themeMode = ThemeMode.system;
    if (themeStr == 'light') _themeMode = ThemeMode.light;

    final colorVal = prefs.getInt(_kSeedColor);
    if (colorVal != null) _seedColor = Color(colorVal);

    final localeStr = prefs.getString(_kLocale);
    if (localeStr != null) _locale = Locale(localeStr);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSeedColor, color.value);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale.languageCode);
  }
}