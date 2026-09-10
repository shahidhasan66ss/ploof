import '../../editor/models/chat_models.dart';

class TemplateMessageSeed {
  const TemplateMessageSeed({
    required this.senderId,
    required this.side,
    required this.text,
    this.reaction,
  });

  final String senderId;
  final MessageSide side;
  final String text;
  final String? reaction;
}

class ChatTemplate {
  const ChatTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.themeId,
    required this.participants,
    required this.messages,
    required this.accentEmoji,
    this.randomReplies = const <String>[],
    this.stickerEmoji,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String themeId;
  final List<ChatParticipant> participants;
  final List<TemplateMessageSeed> messages;
  final String accentEmoji;
  final List<String> randomReplies;
  final String? stickerEmoji;
}
