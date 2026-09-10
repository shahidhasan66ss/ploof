import 'package:flutter_test/flutter_test.dart';

import 'package:chatpop/features/export/models/export_settings.dart';

void main() {
  test('social export dimensions are explicit and stable', () {
    expect(const ExportSettings(size: ExportCanvasSize.square).width, 1080);
    expect(const ExportSettings(size: ExportCanvasSize.square).height, 1080);
    expect(const ExportSettings(size: ExportCanvasSize.portrait).height, 1350);
    expect(const ExportSettings(size: ExportCanvasSize.story).height, 1920);
  });
}
