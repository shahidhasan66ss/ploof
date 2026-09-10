import 'package:flutter_test/flutter_test.dart';

import 'package:chatpop/features/editor/models/chat_models.dart';
import 'package:chatpop/features/editor/providers/editor_provider.dart';

void main() {
  test('editor adds, reorders, and undoes messages', () {
    final EditorNotifier editor = EditorNotifier();
    editor.initializeBlank();
    final int originalLength = editor.state.project!.messages.length;

    editor.addTextMessage(side: MessageSide.outgoing, text: 'A silly reply');
    expect(editor.state.project!.messages, hasLength(originalLength + 1));

    final String addedId = editor.state.project!.messages.last.id;
    editor.moveMessage(addedId, -1);
    expect(editor.state.project!.messages.first.id, addedId);

    editor.undo();
    expect(editor.state.project!.messages.last.id, addedId);

    editor.undo();
    expect(editor.state.project!.messages, hasLength(originalLength));
  });
}
