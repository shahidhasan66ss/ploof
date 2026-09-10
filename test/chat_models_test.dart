import 'package:flutter_test/flutter_test.dart';

import 'package:chatpop/features/editor/models/chat_models.dart';

void main() {
  test('ChatProject round-trips JSON including reactions and stickers', () {
    final DateTime now = DateTime(2026, 9, 10, 12);
    final ChatProject project = ChatProject(
      id: 'one',
      name: 'Funny chat',
      participants: const <ChatParticipant>[
        ChatParticipant(id: 'a', name: 'Alex', initials: 'A', colorValue: 1),
        ChatParticipant(id: 'b', name: 'You', initials: 'Y', colorValue: 2, side: MessageSide.outgoing),
      ],
      messages: <ChatMessage>[
        ChatMessage(id: 'm', senderId: 'a', side: MessageSide.incoming, timestamp: now, text: 'hello', reaction: const ChatReaction(emoji: '😂')),
      ],
      stickers: const <ChatStickerPlacement>[
        ChatStickerPlacement(id: 's', stickerId: 'laugh', emoji: '😂', anchorMessageId: 'm'),
      ],
      themeId: 'bubble-classic',
      createdAt: now,
      updatedAt: now,
    );

    final ChatProject decoded = ChatProject.decode(project.encode());

    expect(decoded.name, 'Funny chat');
    expect(decoded.participants, hasLength(2));
    expect(decoded.messages.single.reaction?.emoji, '😂');
    expect(decoded.stickers.single.anchorMessageId, 'm');
  });

  test('corrupt optional lists recover to empty collections', () {
    final ChatProject decoded = ChatProject.fromJson(<String, dynamic>{
      'id': 'safe',
      'participants': 'not a list',
      'messages': null,
      'createdAt': 'invalid',
      'updatedAt': 'invalid',
    });

    expect(decoded.participants, isEmpty);
    expect(decoded.messages, isEmpty);
  });
}
