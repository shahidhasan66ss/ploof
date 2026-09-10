import 'package:flutter/material.dart';

enum ExportQuality { standard, high }

enum DefaultExportSize { square, portrait, story }

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.exportQuality = ExportQuality.high,
    this.defaultExportSize = DefaultExportSize.portrait,
    this.watermarkEnabled = false,
    this.loaded = false,
  });

  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final ExportQuality exportQuality;
  final DefaultExportSize defaultExportSize;
  final bool watermarkEnabled;
  final bool loaded;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? soundEnabled,
    ExportQuality? exportQuality,
    DefaultExportSize? defaultExportSize,
    bool? watermarkEnabled,
    bool? loaded,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        exportQuality: exportQuality ?? this.exportQuality,
        defaultExportSize: defaultExportSize ?? this.defaultExportSize,
        watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
        loaded: loaded ?? this.loaded,
      );
}
