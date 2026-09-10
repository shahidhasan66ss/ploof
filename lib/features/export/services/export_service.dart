import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/export_settings.dart';

class ExportException implements Exception {
  const ExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExportResult {
  const ExportResult({required this.file, required this.settings});
  final File file;
  final ExportSettings settings;
}

/// Captures the same [ChatExportSurface] shown in preview, at an explicit
/// social-media pixel size. Capture concerns never leak into visual widgets.
class ExportService {
  final Uuid _uuid = const Uuid();

  Future<ExportResult> exportBoundary({
    required GlobalKey boundaryKey,
    required ExportSettings settings,
  }) async {
    try {
      final BuildContext? context = boundaryKey.currentContext;
      final RenderObject? renderObject = context?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize) {
        throw const ExportException('The preview is not ready yet. Please try again.');
      }
      final Size logicalSize = renderObject.size;
      if (logicalSize.width <= 0 || logicalSize.height <= 0) {
        throw const ExportException('The preview has no size to export.');
      }
      final double pixelRatio = settings.width / logicalSize.width;
      final ui.Image rendered = await renderObject.toImage(pixelRatio: pixelRatio);
      final ByteData? data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (data == null) throw const ExportException('Could not render the image bytes.');
      Uint8List bytes = data.buffer.asUint8List();
      if (settings.format == ExportFileFormat.jpg) {
        final image.Image? decoded = image.decodePng(bytes);
        if (decoded == null) throw const ExportException('Could not prepare the JPG image.');
        bytes = Uint8List.fromList(image.encodeJpg(decoded, quality: settings.highQuality ? 96 : 85));
      }
      final Directory documents = await getApplicationDocumentsDirectory();
      final Directory directory = Directory('${documents.path}/${AppConstants.exportsDirectory}');
      if (!await directory.exists()) await directory.create(recursive: true);
      final String extension = settings.format == ExportFileFormat.png ? 'png' : 'jpg';
      final File file = File('${directory.path}/chatpop-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4()}.$extension');
      await file.writeAsBytes(bytes, flush: true);
      return ExportResult(file: file, settings: settings);
    } on ExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ExportException('Could not save the export. ${error.message}');
    } catch (_) {
      throw const ExportException('Export did not work this time. Your chat is still safe in the editor.');
    }
  }

  Future<void> share(ExportResult result) async {
    try {
      await Share.shareXFiles(
        <XFile>[XFile(result.file.path)],
        subject: 'A fictional chat made with ${AppConstants.appName}',
        text: 'Made for fun with ${AppConstants.appName}.',
      );
    } catch (_) {
      throw const ExportException('Could not open sharing. Please try another app.');
    }
  }
}
