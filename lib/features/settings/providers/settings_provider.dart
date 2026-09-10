import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (Ref ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const String _themeKey = 'settings.theme';
  static const String _hapticsKey = 'settings.haptics';
  static const String _soundKey = 'settings.sound';
  static const String _qualityKey = 'settings.quality';
  static const String _sizeKey = 'settings.default_size';
  static const String _watermarkKey = 'settings.watermark';

  Future<void> _load() async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      state = AppSettings(
        themeMode: _themeFromName(preferences.getString(_themeKey)),
        hapticsEnabled: preferences.getBool(_hapticsKey) ?? true,
        soundEnabled: preferences.getBool(_soundKey) ?? false,
        exportQuality: _qualityFromName(preferences.getString(_qualityKey)),
        defaultExportSize: _sizeFromName(preferences.getString(_sizeKey)),
        watermarkEnabled: preferences.getBool(_watermarkKey) ?? false,
        loaded: true,
      );
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await _setString(_themeKey, value.name);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await _setBool(_hapticsKey, value);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _setBool(_soundKey, value);
  }

  Future<void> setExportQuality(ExportQuality value) async {
    state = state.copyWith(exportQuality: value);
    await _setString(_qualityKey, value.name);
  }

  Future<void> setDefaultExportSize(DefaultExportSize value) async {
    state = state.copyWith(defaultExportSize: value);
    await _setString(_sizeKey, value.name);
  }

  Future<void> setWatermark(bool value) async {
    state = state.copyWith(watermarkEnabled: value);
    await _setBool(_watermarkKey, value);
  }

  Future<void> _setString(String key, String value) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, value);
    } catch (_) {
      // Settings are optional conveniences; the in-memory choice still works.
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    } catch (_) {
      // See _setString.
    }
  }
}

ThemeMode _themeFromName(String? value) => ThemeMode.values.firstWhere(
      (ThemeMode item) => item.name == value,
      orElse: () => ThemeMode.system,
    );

ExportQuality _qualityFromName(String? value) => ExportQuality.values.firstWhere(
      (ExportQuality item) => item.name == value,
      orElse: () => ExportQuality.high,
    );

DefaultExportSize _sizeFromName(String? value) => DefaultExportSize.values.firstWhere(
      (DefaultExportSize item) => item.name == value,
      orElse: () => DefaultExportSize.portrait,
    );
