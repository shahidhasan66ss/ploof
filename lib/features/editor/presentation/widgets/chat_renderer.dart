import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_models.dart';
import '../../models/chat_theme.dart';

/// Shared visual language for editor, preview, thumbnail, and export. Only the
/// surrounding layout changes; bubbles, header, reactions, stickers and media
/// all use these exact same widgets.
class ChatRenderer extends StatelessWidget {
  const ChatRenderer({
    required this.project,
    this.selectedMessageId,
    this.onMessageTap,
    this.onStickerTap,
    this.onReorder,
    this.compact = false,
    super.key,
  });

  final ChatProject project;
  final String? selectedMessageId;
  final ValueChanged<ChatMessage>? onMessageTap;
  final ValueChanged<ChatStickerPlacement>? onStickerTap;
  final ReorderCallback? onReorder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ChatThemeStyle theme = themeById(project.themeId);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(compact ? 18 : 26),
        border: Border.all(color: theme.timestamp.withOpacity(.16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 18 : 26),
        child: Column(
          children: <Widget>[
            ChatHeader(project: project, theme: theme, compact: compact),
            Expanded(
              child: onReorder == null
                  ? ListView.builder(
                      padding: EdgeInsets.fromLTRB(compact ? 9 : 14, 12, compact ? 9 : 14, 14),
                      itemCount: project.messages.length,
                      itemBuilder: (BuildContext context, int index) => _MessageRow(
                        message: project.messages[index],
                        project: project,
                        theme: theme,
                        isSelected: selectedMessageId == project.messages[index].id,
                        compact: compact,
                        onMessageTap: onMessageTap,
                        onStickerTap: onStickerTap,
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      buildDefaultDragHandles: false,
                      itemCount: project.messages.length,
                      onReorder: onReorder!,
                      itemBuilder: (BuildContext context, int index) {
                        final ChatMessage message = project.messages[index];
                        return _MessageRow(
                          key: ValueKey<String>(message.id),
                          message: message,
                          project: project,
                          theme: theme,
                          isSelected: selectedMessageId == message.id,
                          dragIndex: index,
                          onMessageTap: onMessageTap,
                          onStickerTap: onStickerTap,
                        );
                      },
                    ),
            ),
            _FakeInput(theme: theme, compact: compact),
          ],
        ),
      ),
    );
  }
}

/// Intrinsic document version used in the export surface. It deliberately uses
/// the same ChatHeader, _MessageRow and _FakeInput implementation as the live
/// editor rather than recreating the chat in an exporter-specific widget.
class ChatDocument extends StatelessWidget {
  const ChatDocument({
    required this.project,
    this.compact = false,
    super.key,
  });

  final ChatProject project;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ChatThemeStyle theme = themeById(project.themeId);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChatHeader(project: project, theme: theme, compact: compact),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 9 : 14, 12, compact ? 9 : 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: project.messages
                  .map(
                    (ChatMessage message) => _MessageRow(
                      message: message,
                      project: project,
                      theme: theme,
                      compact: compact,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          _FakeInput(theme: theme, compact: compact),
        ],
      ),
    );
  }
}

class ChatExportSurface extends StatelessWidget {
  const ChatExportSurface({
    required this.project,
    this.padding = 18,
    super.key,
  });

  final ChatProject project;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final ChatThemeStyle theme = themeById(project.themeId);
    return ColoredBox(
      color: theme.background,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(width: 360, child: ChatDocument(project: project)),
        ),
      ),
    );
  }
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    required this.project,
    required this.theme,
    this.compact = false,
    super.key,
  });

  final ChatProject project;
  final ChatThemeStyle theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ChatParticipant lead = project.participants.isEmpty
        ? const ChatParticipant(id: 'fallback', name: 'Chat', initials: 'C', colorValue: 0xFF7058E7)
        : project.participants.first;
    return Container(
      color: theme.header,
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, compact ? 9 : 13, compact ? 10 : 16, compact ? 8 : 11),
      child: Row(
        children: <Widget>[
          _Avatar(participant: lead, size: compact ? 27 : 34),
          SizedBox(width: compact ? 7 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.headerText,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11 : 15,
                  ),
                ),
                if (!compact)
                  Text(
                    'Fictional • just for fun',
                    style: TextStyle(color: theme.timestamp, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Icon(Icons.more_horiz_rounded, size: compact ? 16 : 22, color: theme.headerText.withOpacity(.75)),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.project,
    required this.theme,
    this.isSelected = false,
    this.dragIndex,
    this.compact = false,
    this.onMessageTap,
    this.onStickerTap,
    super.key,
  });

  final ChatMessage message;
  final ChatProject project;
  final ChatThemeStyle theme;
  final bool isSelected;
  final int? dragIndex;
  final bool compact;
  final ValueChanged<ChatMessage>? onMessageTap;
  final ValueChanged<ChatStickerPlacement>? onStickerTap;

  @override
  Widget build(BuildContext context) {
    final List<ChatStickerPlacement> attached = project.stickers
        .where((ChatStickerPlacement sticker) => sticker.anchorMessageId == message.id)
        .toList(growable: false);
    final bool outgoing = message.side == MessageSide.outgoing;
    final ChatParticipant participant = project.participants.firstWhere(
      (ChatParticipant item) => item.id == message.senderId,
      orElse: () => ChatParticipant(
        id: 'missing',
        name: outgoing ? 'You' : 'Friend',
        initials: outgoing ? 'Y' : 'F',
        colorValue: outgoing ? 0xFF7058E7 : 0xFFF09A65,
        side: message.side,
      ),
    );
    final Widget bubble = _MessageBubble(message: message, theme: theme, compact: compact);
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: compact ? 6 : 10),
          child: Row(
            mainAxisAlignment: outgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!outgoing) ...<Widget>[
                _Avatar(participant: participant, size: compact ? 20 : 27),
                SizedBox(width: compact ? 4 : 7),
              ],
              Flexible(
                child: Semantics(
                  button: onMessageTap != null,
                  label: '${outgoing ? 'Outgoing' : 'Incoming'} message: ${message.text}',
                  child: GestureDetector(
                    onTap: onMessageTap == null ? null : () => onMessageTap!(message),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      decoration: isSelected
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: <BoxShadow>[
                                BoxShadow(color: theme.outgoingBubble.withOpacity(.45), blurRadius: 0, spreadRadius: 2),
                              ],
                            )
                          : null,
                      child: bubble,
                    ),
                  ),
                ),
              ),
              if (outgoing) ...<Widget>[
                SizedBox(width: compact ? 4 : 7),
                _Avatar(participant: participant, size: compact ? 20 : 27),
              ],
              if (dragIndex != null)
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.drag_handle_rounded, color: theme.timestamp, size: 20),
                  ),
                ),
            ],
          ),
        ),
        ...attached.map(
          (ChatStickerPlacement sticker) => Align(
            alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
            child: Semantics(
              button: onStickerTap != null,
              label: '${sticker.label} sticker',
              child: GestureDetector(
                onTap: onStickerTap == null ? null : () => onStickerTap!(sticker),
                child: _StickerBadge(sticker: sticker, compact: compact),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.theme, required this.compact});

  final ChatMessage message;
  final ChatThemeStyle theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool outgoing = message.side == MessageSide.outgoing;
    final Color bubbleColor = outgoing ? theme.outgoingBubble : theme.incomingBubble;
    final Color textColor = outgoing ? theme.outgoingText : theme.incomingText;
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(outgoing ? 18 : 5),
      bottomRight: Radius.circular(outgoing ? 5 : 18),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(maxWidth: compact ? 150 : 270),
          padding: message.type == ChatMessageType.image
              ? const EdgeInsets.all(4)
              : EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 6 : 9),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: _MessageContent(message: message, textColor: textColor, compact: compact),
        ),
        if (message.reaction != null)
          Positioned(
            bottom: compact ? -8 : -10,
            right: outgoing ? 4 : -5,
            child: _ReactionBadge(reaction: message.reaction!, theme: theme, compact: compact),
          ),
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.textColor, required this.compact});

  final ChatMessage message;
  final Color textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.typing) return _TypingDots(color: textColor.withOpacity(.85));
    if (message.type == ChatMessageType.image) {
      final String? path = message.mediaPath;
      if (path == null || path.isEmpty) return const _MediaPlaceholder();
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          width: compact ? 120 : 220,
          height: compact ? 90 : 160,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const _MediaPlaceholder(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: compact ? 9 : 14, height: 1.22, fontWeight: FontWeight.w500),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              _messageMeta(message),
              style: TextStyle(color: textColor.withOpacity(.68), fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  String _messageMeta(ChatMessage message) {
    final String time = DateFormat.jm().format(message.timestamp);
    switch (message.status) {
      case MessageStatus.seen:
        return '$time  •  seen';
      case MessageStatus.delivered:
        return '$time  •  delivered';
      case MessageStatus.sent:
        return '$time  •  sent';
      case MessageStatus.none:
        return time;
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.participant, required this.size});

  final ChatParticipant participant;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Color(participant.colorValue), shape: BoxShape.circle),
        child: Text(
          participant.initials.isEmpty ? '?' : participant.initials.substring(0, 1).toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: size * .39, fontWeight: FontWeight.w900),
        ),
      );
}

class _ReactionBadge extends StatelessWidget {
  const _ReactionBadge({required this.reaction, required this.theme, required this.compact});

  final ChatReaction reaction;
  final ChatThemeStyle theme;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 5, vertical: compact ? 1 : 2),
        decoration: BoxDecoration(
          color: theme.reactionSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.timestamp.withOpacity(.28)),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.09), blurRadius: 4)],
        ),
        child: Text(reaction.emoji, style: TextStyle(fontSize: compact ? 9 : 14)),
      );
}

class _StickerBadge extends StatelessWidget {
  const _StickerBadge({required this.sticker, required this.compact});

  final ChatStickerPlacement sticker;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: compact ? 4 : 8),
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: compact ? 2 : 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.9),
          borderRadius: BorderRadius.circular(100),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 5)],
        ),
        child: Text(sticker.emoji, style: TextStyle(fontSize: compact ? 18 : 29)),
      );
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 40,
        height: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List<Widget>.generate(
            3,
            (int index) => Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
        ),
      );
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        height: 110,
        color: const Color(0xFF42386E),
        alignment: Alignment.center,
        child: const Icon(Icons.image_rounded, color: Colors.white, size: 36),
      );
}

class _FakeInput extends StatelessWidget {
  const _FakeInput({required this.theme, required this.compact});
  final ChatThemeStyle theme;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        color: theme.surface,
        padding: EdgeInsets.fromLTRB(compact ? 8 : 13, compact ? 6 : 10, compact ? 8 : 13, compact ? 8 : 12),
        child: Container(
          height: compact ? 20 : 34,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 11),
          decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(100)),
          child: Row(
            children: <Widget>[
              Icon(Icons.add_circle_outline_rounded, size: compact ? 11 : 18, color: theme.timestamp),
              SizedBox(width: compact ? 4 : 7),
              Text('Message', style: TextStyle(fontSize: compact ? 7 : 11, color: theme.timestamp)),
              const Spacer(),
              Icon(Icons.sentiment_satisfied_alt_rounded, size: compact ? 11 : 18, color: theme.timestamp),
            ],
          ),
        ),
      );
}
