import 'dart:convert';

enum MessageSide { incoming, outgoing }

enum ChatMessageType { text, image, typing }

enum MessageStatus { none, sent, delivered, seen }

/// A fictional person in a ChatPop project. Avatars are initials and colors,
/// deliberately avoiding any claim to a real-world identity.
class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.initials,
    required this.colorValue,
    this.side = MessageSide.incoming,
  });

  final String id;
  final String name;
  final String initials;
  final int colorValue;
  final MessageSide side;

  ChatParticipant copyWith({
    String? id,
    String? name,
    String? initials,
    int? colorValue,
    MessageSide? side,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      colorValue: colorValue ?? this.colorValue,
      side: side ?? this.side,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'initials': initials,
        'colorValue': colorValue,
        'side': side.name,
      };

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Friend',
      initials: json['initials'] as String? ?? '?',
      colorValue: json['colorValue'] as int? ?? 0xFF7C5CFC,
      side: _sideFromName(json['side'] as String?),
    );
  }
}

class ChatReaction {
  const ChatReaction({required this.emoji, this.label});

  final String emoji;
  final String? label;

  Map<String, Object?> toJson() => <String, Object?>{
        'emoji': emoji,
        'label': label,
      };

  factory ChatReaction.fromJson(Map<String, dynamic> json) => ChatReaction(
        emoji: json['emoji'] as String? ?? '😂',
        label: json['label'] as String?,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.side,
    required this.timestamp,
    this.text = '',
    this.type = ChatMessageType.text,
    this.reaction,
    this.mediaPath,
    this.status = MessageStatus.none,
  });

  final String id;
  final String senderId;
  final MessageSide side;
  final DateTime timestamp;
  final String text;
  final ChatMessageType type;
  final ChatReaction? reaction;
  final String? mediaPath;
  final MessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    MessageSide? side,
    DateTime? timestamp,
    String? text,
    ChatMessageType? type,
    ChatReaction? reaction,
    bool clearReaction = false,
    String? mediaPath,
    bool clearMedia = false,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      side: side ?? this.side,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      type: type ?? this.type,
      reaction: clearReaction ? null : reaction ?? this.reaction,
      mediaPath: clearMedia ? null : mediaPath ?? this.mediaPath,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'senderId': senderId,
        'side': side.name,
        'timestamp': timestamp.toIso8601String(),
        'text': text,
        'type': type.name,
        'reaction': reaction?.toJson(),
        'mediaPath': mediaPath,
        'status': status.name,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final Object? reaction = json['reaction'];
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String? ?? 'friend',
      side: _sideFromName(json['side'] as String?),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      text: json['text'] as String? ?? '',
      type: _typeFromName(json['type'] as String?),
      reaction: reaction is Map<String, dynamic> ? ChatReaction.fromJson(reaction) : null,
      mediaPath: json['mediaPath'] as String?,
      status: _statusFromName(json['status'] as String?),
    );
  }
}

/// A sticker is anchored after a message so it stays part of the conversation
/// without needing a second, unrelated canvas implementation.
class ChatStickerPlacement {
  const ChatStickerPlacement({
    required this.id,
    required this.stickerId,
    required this.emoji,
    required this.anchorMessageId,
    this.label = '',
  });

  final String id;
  final String stickerId;
  final String emoji;
  final String anchorMessageId;
  final String label;

  ChatStickerPlacement copyWith({
    String? id,
    String? stickerId,
    String? emoji,
    String? anchorMessageId,
    String? label,
  }) =>
      ChatStickerPlacement(
        id: id ?? this.id,
        stickerId: stickerId ?? this.stickerId,
        emoji: emoji ?? this.emoji,
        anchorMessageId: anchorMessageId ?? this.anchorMessageId,
        label: label ?? this.label,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'stickerId': stickerId,
        'emoji': emoji,
        'anchorMessageId': anchorMessageId,
        'label': label,
      };

  factory ChatStickerPlacement.fromJson(Map<String, dynamic> json) => ChatStickerPlacement(
        id: json['id'] as String,
        stickerId: json['stickerId'] as String? ?? 'laugh',
        emoji: json['emoji'] as String? ?? '😂',
        anchorMessageId: json['anchorMessageId'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class ChatProject {
  const ChatProject({
    required this.id,
    required this.name,
    required this.participants,
    required this.messages,
    required this.themeId,
    required this.createdAt,
    required this.updatedAt,
    this.templateId,
    this.stickers = const <ChatStickerPlacement>[],
  });

  final String id;
  final String name;
  final String? templateId;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final List<ChatStickerPlacement> stickers;
  final String themeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatProject copyWith({
    String? id,
    String? name,
    String? templateId,
    bool clearTemplateId = false,
    List<ChatParticipant>? participants,
    List<ChatMessage>? messages,
    List<ChatStickerPlacement>? stickers,
    String? themeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatProject(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: clearTemplateId ? null : templateId ?? this.templateId,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      stickers: stickers ?? this.stickers,
      themeId: themeId ?? this.themeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'templateId': templateId,
        'participants': participants.map((ChatParticipant item) => item.toJson()).toList(),
        'messages': messages.map((ChatMessage item) => item.toJson()).toList(),
        'stickers': stickers.map((ChatStickerPlacement item) => item.toJson()).toList(),
        'themeId': themeId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory ChatProject.fromJson(Map<String, dynamic> json) {
    List<T> decodeList<T>(String key, T Function(Map<String, dynamic>) builder) {
      final Object? value = json[key];
      if (value is! List) return <T>[];
      return value
          .whereType<Map>()
          .map((Map item) => builder(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ChatProject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled chat',
      templateId: json['templateId'] as String?,
      participants: decodeList('participants', ChatParticipant.fromJson),
      messages: decodeList('messages', ChatMessage.fromJson),
      stickers: decodeList('stickers', ChatStickerPlacement.fromJson),
      themeId: json['themeId'] as String? ?? 'bubble-classic',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory ChatProject.decode(String source) =>
      ChatProject.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

MessageSide _sideFromName(String? value) => value == MessageSide.outgoing.name
    ? MessageSide.outgoing
    : MessageSide.incoming;

ChatMessageType _typeFromName(String? value) {
  return ChatMessageType.values.firstWhere(
    (ChatMessageType item) => item.name == value,
    orElse: () => ChatMessageType.text,
  );
}

MessageStatus _statusFromName(String? value) {
  return MessageStatus.values.firstWhere(
    (MessageStatus item) => item.name == value,
    orElse: () => MessageStatus.none,
  );
}
