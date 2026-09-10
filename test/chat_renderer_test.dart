import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatpop/features/editor/models/chat_models.dart';
import 'package:chatpop/features/editor/presentation/widgets/chat_renderer.dart';

void main() {
  testWidgets('renderer shows fictional label and a long message without overflow', (WidgetTester tester) async {
    final ChatProject project = ChatProject(
      id: 'p',
      name: 'Long message test',
      participants: const <ChatParticipant>[
        ChatParticipant(id: 'friend', name: 'Alex', initials: 'A', colorValue: 0xFFF09A65),
      ],
      messages: <ChatMessage>[
        ChatMessage(
          id: 'm',
          senderId: 'friend',
          side: MessageSide.incoming,
          timestamp: DateTime(2026),
          text: 'This is an intentionally long message that should wrap naturally inside the fictional ChatPop bubble instead of clipping out of the canvas.',
        ),
      ],
      themeId: 'bubble-classic',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 360, height: 500, child: ChatRenderer(project: project)))));

    expect(find.text('Fictional • just for fun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
