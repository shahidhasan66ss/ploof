enum ExportCanvasSize { square, portrait, story, adaptive }

enum ExportFileFormat { png, jpg }

class ExportSettings {
  const ExportSettings({
    this.size = ExportCanvasSize.portrait,
    this.format = ExportFileFormat.png,
    this.highQuality = true,
  });

  final ExportCanvasSize size;
  final ExportFileFormat format;
  final bool highQuality;

  int get width {
    switch (size) {
      case ExportCanvasSize.square:
      case ExportCanvasSize.portrait:
      case ExportCanvasSize.story:
      case ExportCanvasSize.adaptive:
        return 1080;
    }
  }

  int get height {
    switch (size) {
      case ExportCanvasSize.square:
        return 1080;
      case ExportCanvasSize.portrait:
      case ExportCanvasSize.adaptive:
        return 1350;
      case ExportCanvasSize.story:
        return 1920;
    }
  }

  double get aspectRatio => width / height;
  String get sizeLabel {
    switch (size) {
      case ExportCanvasSize.square:
        return 'Square · 1080 × 1080';
      case ExportCanvasSize.portrait:
        return 'Portrait · 1080 × 1350';
      case ExportCanvasSize.story:
        return 'Story · 1080 × 1920';
      case ExportCanvasSize.adaptive:
        return 'Chat screenshot · adaptive';
    }
  }

  ExportSettings copyWith({ExportCanvasSize? size, ExportFileFormat? format, bool? highQuality}) => ExportSettings(
        size: size ?? this.size,
        format: format ?? this.format,
        highQuality: highQuality ?? this.highQuality,
      );
}
