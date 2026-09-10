import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            _SectionLabel(label: 'Appearance'),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: const Text('App appearance'),
                    subtitle: Text(_themeLabel(settings.themeMode)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickTheme(context, controller, settings.themeMode),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Feel'),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded),
                    title: const Text('Haptics'),
                    subtitle: const Text('Tiny taps for editor actions'),
                    value: settings.hapticsEnabled,
                    onChanged: controller.setHaptics,
                  ),

                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Export'),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.high_quality_rounded),
                    title: const Text('Export quality'),
                    subtitle: Text(settings.exportQuality == ExportQuality.high ? 'High' : 'Standard'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickQuality(context, controller, settings.exportQuality),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.crop_portrait_rounded),
                    title: const Text('Default export size'),
                    subtitle: Text(_sizeLabel(settings.defaultExportSize)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickDefaultSize(context, controller, settings.defaultExportSize),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'About ${AppConstants.appName}'),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About, privacy & terms'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/about'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('Share app'),
                    onTap: () => Share.share('Make funny fictional chat stories offline with ${AppConstants.appName}.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mail_outline_rounded),
                    title: const Text('Feedback'),
                    subtitle: const Text('Copy feedback address'),
                    onTap: () async {
                      await Clipboard.setData(const ClipboardData(text: 'feedback@chatpop.app'));
                      if (context.mounted) _message(context, 'Feedback address copied.');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(child: Text('Version 1.0.0', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, SettingsNotifier controller, ThemeMode current) async {
    final ThemeMode? result = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (BuildContext context) => _ChoiceSheet<ThemeMode>(
        title: 'App appearance',
        selected: current,
        options: const <_ChoiceOption<ThemeMode>>[
          _ChoiceOption<ThemeMode>(ThemeMode.system, 'System', Icons.brightness_auto_rounded),
          _ChoiceOption<ThemeMode>(ThemeMode.light, 'Light', Icons.light_mode_outlined),
          _ChoiceOption<ThemeMode>(ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
        ],
      ),
    );
    if (result != null) await controller.setThemeMode(result);
  }

  Future<void> _pickQuality(BuildContext context, SettingsNotifier controller, ExportQuality current) async {
    final ExportQuality? result = await showModalBottomSheet<ExportQuality>(
      context: context,
      builder: (BuildContext context) => _ChoiceSheet<ExportQuality>(
        title: 'Export quality',
        selected: current,
        options: const <_ChoiceOption<ExportQuality>>[
          _ChoiceOption<ExportQuality>(ExportQuality.standard, 'Standard', Icons.image_outlined),
          _ChoiceOption<ExportQuality>(ExportQuality.high, 'High', Icons.high_quality_rounded),
        ],
      ),
    );
    if (result != null) await controller.setExportQuality(result);
  }

  Future<void> _pickDefaultSize(BuildContext context, SettingsNotifier controller, DefaultExportSize current) async {
    final DefaultExportSize? result = await showModalBottomSheet<DefaultExportSize>(
      context: context,
      builder: (BuildContext context) => _ChoiceSheet<DefaultExportSize>(
        title: 'Default export size',
        selected: current,
        options: const <_ChoiceOption<DefaultExportSize>>[
          _ChoiceOption<DefaultExportSize>(DefaultExportSize.square, 'Square · 1080 × 1080', Icons.crop_square_rounded),
          _ChoiceOption<DefaultExportSize>(DefaultExportSize.portrait, 'Portrait · 1080 × 1350', Icons.crop_portrait_rounded),
          _ChoiceOption<DefaultExportSize>(DefaultExportSize.story, 'Story · 1080 × 1920', Icons.phone_android_rounded),
        ],
      ),
    );
    if (result != null) await controller.setDefaultExportSize(result);
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  String _sizeLabel(DefaultExportSize size) => switch (size) {
        DefaultExportSize.square => 'Square · 1080 × 1080',
        DefaultExportSize.portrait => 'Portrait · 1080 × 1350',
        DefaultExportSize.story => 'Story · 1080 × 1920',
      };

  void _message(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: .7)),
      );
}

class _ChoiceOption<T> {
  const _ChoiceOption(this.value, this.label, this.icon);
  final T value;
  final String label;
  final IconData icon;
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({required this.title, required this.selected, required this.options});
  final String title;
  final T selected;
  final List<_ChoiceOption<T>> options;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.fromLTRB(8, 0, 0, 8), child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)))),
              ...options.map(
                (_ChoiceOption<T> option) => ListTile(
                  leading: Icon(option.icon),
                  title: Text(option.label),
                  trailing: option.value == selected ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, option.value),
                ),
              ),
            ],
          ),
        ),
      );
}
