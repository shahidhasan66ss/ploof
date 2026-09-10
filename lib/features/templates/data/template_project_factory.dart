import '../../editor/models/chat_models.dart';
import '../models/chat_template.dart';

ChatProject templatePreviewProject(ChatTemplate template) {
  final DateTime time = DateTime(2026, 1, 1, 12);
  final List<ChatMessage> messages = <ChatMessage>[
    for (int index = 0; index < template.messages.length; index++)
      ChatMessage(
        id: 'preview-${template.id}-$index',
        senderId: template.messages[index].senderId,
        side: template.messages[index].side,
        timestamp: time.add(Duration(minutes: index)),
        text: template.messages[index].text,
      ),
  ];
  return ChatProject(
    id: 'preview-${template.id}',
    name: template.name,
    templateId: template.id,
    participants: template.participants,
    messages: messages,
    stickers: template.stickerEmoji == null || messages.isEmpty
        ? const <ChatStickerPlacement>[]
        : <ChatStickerPlacement>[
            ChatStickerPlacement(
              id: 'preview-sticker-${template.id}',
              stickerId: 'preview',
              emoji: template.stickerEmoji!,
              anchorMessageId: messages.last.id,
              label: template.name,
            ),
          ],
    themeId: template.themeId,
    createdAt: time,
    updatedAt: time,
  );
}
