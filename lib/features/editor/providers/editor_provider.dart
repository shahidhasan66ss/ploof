import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../stickers/models/sticker.dart';
import '../../templates/data/built_in_templates.dart';
import '../../templates/models/chat_template.dart';
import '../models/chat_models.dart';

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (Ref ref) => EditorNotifier(),
);

class EditorState {
  const EditorState({
    this.project,
    this.selectedMessageId,
    this.undoStack = const <ChatProject>[],
    this.redoStack = const <ChatProject>[],
    this.isReady = false,
    this.errorMessage,
  });

  final ChatProject? project;
  final String? selectedMessageId;
  final List<ChatProject> undoStack;
  final List<ChatProject> redoStack;
  final bool isReady;
  final String? errorMessage;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  EditorState copyWith({
    ChatProject? project,
    bool clearProject = false,
    String? selectedMessageId,
    bool clearSelection = false,
    List<ChatProject>? undoStack,
    List<ChatProject>? redoStack,
    bool? isReady,
    String? errorMessage,
    bool clearError = false,
  }) =>
      EditorState(
        project: clearProject ? null : project ?? this.project,
        selectedMessageId: clearSelection ? null : selectedMessageId ?? this.selectedMessageId,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
        isReady: isReady ?? this.isReady,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

/// Snapshot history keeps operations reliable and straightforward. The cap is
/// intentionally small: chat projects are lightweight JSON structures.
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  static const int _historyLimit = 40;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  void initializeBlank() {
    final DateTime now = DateTime.now();
    initializeProject(
      ChatProject(
        id: _uuid.v4(),
        name: 'Untitled chat',
        participants: <ChatParticipant>[
          const ChatParticipant(id: 'friend', name: 'Alex', initials: 'A', colorValue: 0xFFF09A65),
          const ChatParticipant(
            id: 'me',
            name: 'You',
            initials: 'Y',
            colorValue: 0xFF7058E7,
            side: MessageSide.outgoing,
          ),
        ],
        messages: <ChatMessage>[
          ChatMessage(
            id: _uuid.v4(),
            senderId: 'friend',
            side: MessageSide.incoming,
            timestamp: now,
            text: 'Start something funny.',
          ),
        ],
        themeId: 'bubble-classic',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void initializeTemplate(ChatTemplate template) {
    final DateTime now = DateTime.now();
    final List<ChatMessage> messages = <ChatMessage>[];
    for (int index = 0; index < template.messages.length; index++) {
      final TemplateMessageSeed seed = template.messages[index];
      messages.add(
        ChatMessage(
          id: _uuid.v4(),
          senderId: seed.senderId,
          side: seed.side,
          timestamp: now.add(Duration(minutes: index)),
          text: seed.text,
          reaction: seed.reaction == null ? null : ChatReaction(emoji: seed.reaction!),
          status: index == template.messages.length - 1 && seed.side == MessageSide.outgoing
              ? MessageStatus.seen
              : MessageStatus.none,
        ),
      );
    }
    final List<ChatStickerPlacement> stickers = template.stickerEmoji == null || messages.isEmpty
        ? const <ChatStickerPlacement>[]
        : <ChatStickerPlacement>[
            ChatStickerPlacement(
              id: _uuid.v4(),
              stickerId: 'template-${template.id}',
              emoji: template.stickerEmoji!,
              anchorMessageId: messages.last.id,
              label: template.name,
            ),
          ];
    initializeProject(
      ChatProject(
        id: _uuid.v4(),
        name: template.name,
        templateId: template.id,
        participants: List<ChatParticipant>.from(template.participants),
        messages: messages,
        stickers: stickers,
        themeId: template.themeId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void initializeProject(ChatProject project) {
    // Recover a usable project when an old/corrupt JSON file lacks people.
    final ChatProject safeProject = project.participants.isEmpty
        ? project.copyWith(
            participants: const <ChatParticipant>[
              ChatParticipant(id: 'friend', name: 'Alex', initials: 'A', colorValue: 0xFFF09A65),
              ChatParticipant(id: 'me', name: 'You', initials: 'Y', colorValue: 0xFF7058E7, side: MessageSide.outgoing),
            ],
          )
        : project;
    state = EditorState(project: safeProject, isReady: true);
  }

  void selectMessage(String? id) => state = state.copyWith(
        selectedMessageId: id,
        clearSelection: id == null,
      );

  void setProjectTitle(String name) {
    _perform((ChatProject project) => project.copyWith(name: _safeText(name, 'Untitled chat')));
  }

  void updateParticipant(ChatParticipant participant) {
    _perform((ChatProject project) {
      final List<ChatParticipant> updated = project.participants
          .map((ChatParticipant item) => item.id == participant.id ? participant : item)
          .toList(growable: false);
      return project.copyWith(participants: updated);
    });
  }

  void changeTheme(String themeId) =>
      _perform((ChatProject project) => project.copyWith(themeId: themeId));

  void addTextMessage({required MessageSide side, required String text, String? senderId}) {
    final String safeText = text.trim();
    if (safeText.isEmpty) return;
    _perform((ChatProject project) {
      final String sender = senderId ?? _senderForSide(project, side);
      final ChatMessage message = ChatMessage(
        id: _uuid.v4(),
        senderId: sender,
        side: side,
        timestamp: DateTime.now(),
        text: safeText,
        status: side == MessageSide.outgoing ? MessageStatus.sent : MessageStatus.none,
      );
      return project.copyWith(messages: <ChatMessage>[...project.messages, message]);
    });
  }

  void addTyping({required MessageSide side}) {
    _perform((ChatProject project) {
      final ChatMessage message = ChatMessage(
        id: _uuid.v4(),
        senderId: _senderForSide(project, side),
        side: side,
        timestamp: DateTime.now(),
        type: ChatMessageType.typing,
      );
      return project.copyWith(messages: <ChatMessage>[...project.messages, message]);
    });
  }

  void addMedia({required MessageSide side, required String path}) {
    _perform((ChatProject project) {
      final ChatMessage message = ChatMessage(
        id: _uuid.v4(),
        senderId: _senderForSide(project, side),
        side: side,
        timestamp: DateTime.now(),
        type: ChatMessageType.image,
        mediaPath: path,
        text: 'Photo',
        status: side == MessageSide.outgoing ? MessageStatus.sent : MessageStatus.none,
      );
      return project.copyWith(messages: <ChatMessage>[...project.messages, message]);
    });
  }

  void updateMessage(ChatMessage message) {
    _perform((ChatProject project) => project.copyWith(
          messages: project.messages
              .map((ChatMessage item) => item.id == message.id ? message : item)
              .toList(growable: false),
        ));
  }

  void deleteMessage(String id) {
    _perform((ChatProject project) => project.copyWith(
          messages: project.messages.where((ChatMessage item) => item.id != id).toList(),
          stickers: project.stickers
              .where((ChatStickerPlacement item) => item.anchorMessageId != id)
              .toList(),
        ));
    if (state.selectedMessageId == id) selectMessage(null);
  }

  void duplicateMessage(String id) {
    _perform((ChatProject project) {
      final int index = project.messages.indexWhere((ChatMessage item) => item.id == id);
      if (index < 0) return project;
      final ChatMessage original = project.messages[index];
      final ChatMessage copy = original.copyWith(
        id: _uuid.v4(),
        timestamp: original.timestamp.add(const Duration(minutes: 1)),
      );
      final List<ChatMessage> messages = <ChatMessage>[...project.messages]..insert(index + 1, copy);
      return project.copyWith(messages: messages);
    });
  }

  void moveMessage(String id, int direction) {
    _perform((ChatProject project) {
      final int oldIndex = project.messages.indexWhere((ChatMessage item) => item.id == id);
      final int newIndex = oldIndex + direction;
      if (oldIndex < 0 || newIndex < 0 || newIndex >= project.messages.length) return project;
      final List<ChatMessage> messages = <ChatMessage>[...project.messages];
      final ChatMessage message = messages.removeAt(oldIndex);
      messages.insert(newIndex, message);
      return project.copyWith(messages: messages);
    });
  }

  void reorderMessages(int oldIndex, int newIndex) {
    final ChatProject? project = state.project;
    if (project == null || oldIndex < 0 || oldIndex >= project.messages.length) return;
    int target = newIndex;
    if (target > oldIndex) target--;
    if (target < 0 || target >= project.messages.length || target == oldIndex) return;
    _perform((ChatProject current) {
      final List<ChatMessage> messages = <ChatMessage>[...current.messages];
      final ChatMessage message = messages.removeAt(oldIndex);
      messages.insert(target, message);
      return current.copyWith(messages: messages);
    });
  }

  void addReaction(String messageId, String emoji) {
    final ChatMessage? message = _messageById(messageId);
    if (message == null) return;
    updateMessage(message.copyWith(reaction: ChatReaction(emoji: emoji)));
  }

  void removeReaction(String messageId) {
    final ChatMessage? message = _messageById(messageId);
    if (message == null) return;
    updateMessage(message.copyWith(clearReaction: true));
  }

  void addSticker(StickerItem sticker, {String? anchorMessageId}) {
    _perform((ChatProject project) {
      final String? anchor = anchorMessageId ?? state.selectedMessageId ??
          (project.messages.isEmpty ? null : project.messages.last.id);
      if (anchor == null) return project;
      return project.copyWith(
        stickers: <ChatStickerPlacement>[
          ...project.stickers,
          ChatStickerPlacement(
            id: _uuid.v4(),
            stickerId: sticker.id,
            emoji: sticker.emoji,
            anchorMessageId: anchor,
            label: sticker.label,
          ),
        ],
      );
    });
  }

  void removeSticker(String id) => _perform((ChatProject project) => project.copyWith(
        stickers: project.stickers.where((ChatStickerPlacement item) => item.id != id).toList(),
      ));

  void randomizeTemplate() {
    final ChatProject? current = state.project;
    if (current == null || current.messages.isEmpty) return;
    final String reply = localResponses[_random.nextInt(localResponses.length)];
    final int index = _random.nextInt(current.messages.length);
    _perform((ChatProject project) {
      final List<ChatMessage> messages = <ChatMessage>[...project.messages];
      messages[index] = messages[index].copyWith(text: reply);
      return project.copyWith(messages: messages);
    });
  }

  void undo() {
    final ChatProject? current = state.project;
    if (current == null || state.undoStack.isEmpty) return;
    final List<ChatProject> undo = <ChatProject>[...state.undoStack];
    final ChatProject previous = undo.removeLast();
    state = state.copyWith(
      project: previous,
      undoStack: undo,
      redoStack: <ChatProject>[...state.redoStack, current],
      clearSelection: true,
    );
  }

  void redo() {
    final ChatProject? current = state.project;
    if (current == null || state.redoStack.isEmpty) return;
    final List<ChatProject> redo = <ChatProject>[...state.redoStack];
    final ChatProject next = redo.removeLast();
    state = state.copyWith(
      project: next,
      undoStack: _capped(<ChatProject>[...state.undoStack, current]),
      redoStack: redo,
      clearSelection: true,
    );
  }

  void _perform(ChatProject Function(ChatProject project) action) {
    final ChatProject? current = state.project;
    if (current == null) return;
    final ChatProject result = action(current).copyWith(updatedAt: DateTime.now());
    if (identical(result, current)) return;
    state = state.copyWith(
      project: result,
      undoStack: _capped(<ChatProject>[...state.undoStack, current]),
      redoStack: const <ChatProject>[],
      clearError: true,
    );
  }

  List<ChatProject> _capped(List<ChatProject> values) => values.length <= _historyLimit
      ? values
      : values.sublist(values.length - _historyLimit);

  ChatMessage? _messageById(String id) {
    final ChatProject? project = state.project;
    if (project == null) return null;
    for (final ChatMessage message in project.messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  String _senderForSide(ChatProject project, MessageSide side) {
    if (project.participants.isEmpty) return side == MessageSide.outgoing ? 'me' : 'friend';
    return project.participants
        .firstWhere(
          (ChatParticipant participant) => participant.side == side,
          orElse: () => project.participants.first,
        )
        .id;
  }

  String _safeText(String value, String fallback) => value.trim().isEmpty ? fallback : value.trim();
}
