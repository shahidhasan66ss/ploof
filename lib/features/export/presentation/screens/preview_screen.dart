import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/haptics_service.dart';
import '../../../creations/providers/creation_provider.dart';
import '../../../editor/presentation/widgets/chat_renderer.dart';
import '../../../editor/providers/editor_provider.dart';
import '../../../settings/models/app_settings.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../models/export_settings.dart';
import '../../services/export_service.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final ExportService _exportService = ExportService();
  final HapticsService _haptics = const HapticsService();
  ExportSettings? _settings;
  ExportResult? _result;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final project = editorState.project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/'), child: const Text('Back home')),
        ),
      );
    }
    final ExportSettings exportSettings = _settings ?? _initialSettings(ref.watch(settingsProvider));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to editor',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Export preview'),
        actions: <Widget>[
          IconButton(tooltip: 'Save creation', onPressed: _saveProject, icon: const Icon(Icons.save_outlined)),
          TextButton.icon(
            onPressed: _isExporting ? null : _export,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Center(
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: AspectRatio(
                      aspectRatio: exportSettings.aspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 10))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ChatExportSurface(project: project),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _ExportControls(
              settings: exportSettings,
              isExporting: _isExporting,
              exportResult: _result,
              onSizeChanged: (ExportCanvasSize size) => setState(() {
                _settings = exportSettings.copyWith(size: size);
                _result = null;
              }),
              onFormatChanged: (ExportFileFormat format) => setState(() {
                _settings = exportSettings.copyWith(format: format);
                _result = null;
              }),
              onExport: _export,
              onShare: _share,
              onCreateAnother: () => context.go('/create'),
            ),
          ],
        ),
      ),
    );
  }

  ExportSettings _initialSettings(AppSettings settings) {
    final ExportCanvasSize size;
    switch (settings.defaultExportSize) {
      case DefaultExportSize.square:
        size = ExportCanvasSize.square;
        break;
      case DefaultExportSize.portrait:
        size = ExportCanvasSize.portrait;
        break;
      case DefaultExportSize.story:
        size = ExportCanvasSize.story;
        break;
    }
    return ExportSettings(size: size, highQuality: settings.exportQuality == ExportQuality.high);
  }

  Future<void> _saveProject() async {
    final project = ref.read(editorProvider).project;
    if (project == null) return;
    try {
      await ref.read(creationsProvider.notifier).save(project);
      if (mounted) _showMessage('Saved to My Creations.');
    } catch (_) {
      if (mounted) _showMessage('Could not save this creation.');
    }
  }

  Future<void> _export() async {
    if (_isExporting) return;
    final ExportSettings settings = _settings ?? _initialSettings(ref.read(settingsProvider));
    setState(() => _isExporting = true);
    try {
      final ExportResult result = await _exportService.exportBoundary(boundaryKey: _captureKey, settings: settings);
      if (!mounted) return;
      setState(() => _result = result);
      await _haptics.success(enabled: ref.read(settingsProvider).hapticsEnabled);
      if (mounted) _showMessage('Export complete. Saved locally on this device.');
    } on ExportException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _share() async {
    final ExportResult? result = _result;
    if (result == null) {
      await _export();
      if (!mounted || _result == null) return;
    }
    try {
      await _exportService.share(_result!);
    } on ExportException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ExportControls extends StatelessWidget {
  const _ExportControls({
    required this.settings,
    required this.isExporting,
    required this.exportResult,
    required this.onSizeChanged,
    required this.onFormatChanged,
    required this.onExport,
    required this.onShare,
    required this.onCreateAnother,
  });

  final ExportSettings settings;
  final bool isExporting;
  final ExportResult? exportResult;
  final ValueChanged<ExportCanvasSize> onSizeChanged;
  final ValueChanged<ExportFileFormat> onFormatChanged;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onCreateAnother;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 10,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Format your share', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final ExportCanvasSize size in <ExportCanvasSize>[ExportCanvasSize.square, ExportCanvasSize.portrait, ExportCanvasSize.story])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_sizeShortLabel(size)),
                            selected: settings.size == size,
                            onSelected: (_) => onSizeChanged(size),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Text('File', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 8),
                    SegmentedButton<ExportFileFormat>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<ExportFileFormat>>[
                        ButtonSegment<ExportFileFormat>(value: ExportFileFormat.png, label: Text('PNG')),
                        ButtonSegment<ExportFileFormat>(value: ExportFileFormat.jpg, label: Text('JPG')),
                      ],
                      selected: <ExportFileFormat>{settings.format},
                      onSelectionChanged: (Set<ExportFileFormat> value) => onFormatChanged(value.first),
                    ),
                    const Spacer(),
                    Text(settings.sizeLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 12),
                if (exportResult == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isExporting ? null : onExport,
                      icon: isExporting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.file_download_rounded),
                      label: Text(isExporting ? 'Rendering your chat...' : 'Export ${settings.format.name.toUpperCase()}'),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF36A575)),
                          const SizedBox(width: 8),
                          Text('Share your creation', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(child: FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded), label: const Text('Share'))),
                          const SizedBox(width: 10),
                          OutlinedButton(onPressed: onCreateAnother, child: const Text('Create another')),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

  String _sizeShortLabel(ExportCanvasSize size) {
    switch (size) {
      case ExportCanvasSize.square:
        return 'Square';
      case ExportCanvasSize.portrait:
        return 'Portrait';
      case ExportCanvasSize.story:
        return 'Story';
      case ExportCanvasSize.adaptive:
        return 'Adaptive';
    }
  }
}
