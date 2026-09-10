import 'package:flutter/material.dart';

/// A deliberately original set of visual tokens for fictional ChatPop chats.
class ChatThemeStyle {
  const ChatThemeStyle({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.incomingText,
    required this.outgoingText,
    required this.header,
    required this.headerText,
    required this.timestamp,
    required this.reactionSurface,
    this.isDark = false,
  });

  final String id;
  final String name;
  final Color background;
  final Color surface;
  final Color incomingBubble;
  final Color outgoingBubble;
  final Color incomingText;
  final Color outgoingText;
  final Color header;
  final Color headerText;
  final Color timestamp;
  final Color reactionSurface;
  final bool isDark;
}

const List<ChatThemeStyle> chatThemes = <ChatThemeStyle>[
  ChatThemeStyle(
    id: 'bubble-classic',
    name: 'Bubble Classic',
    background: Color(0xFFF8F7FC),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFECEAF3),
    outgoingBubble: Color(0xFF6E55E8),
    incomingText: Color(0xFF272336),
    outgoingText: Color(0xFFFFFFFF),
    header: Color(0xFFFFFFFF),
    headerText: Color(0xFF272336),
    timestamp: Color(0xFF817D91),
    reactionSurface: Color(0xFFFFFFFF),
  ),
  ChatThemeStyle(
    id: 'midnight-chat',
    name: 'Midnight Chat',
    background: Color(0xFF111322),
    surface: Color(0xFF1D2033),
    incomingBubble: Color(0xFF2A2E46),
    outgoingBubble: Color(0xFF8E73FF),
    incomingText: Color(0xFFF4F2FF),
    outgoingText: Color(0xFF10101A),
    header: Color(0xFF1D2033),
    headerText: Color(0xFFF5F2FF),
    timestamp: Color(0xFFB7B0CD),
    reactionSurface: Color(0xFF363A54),
    isDark: true,
  ),
  ChatThemeStyle(
    id: 'soft-chat',
    name: 'Soft Chat',
    background: Color(0xFFFFF6F3),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFF4E6E0),
    outgoingBubble: Color(0xFFF08A74),
    incomingText: Color(0xFF3A2825),
    outgoingText: Color(0xFFFFFFFF),
    header: Color(0xFFFFFBF9),
    headerText: Color(0xFF3A2825),
    timestamp: Color(0xFF9B7770),
    reactionSurface: Color(0xFFFFFFFF),
  ),
  ChatThemeStyle(
    id: 'neon-pop',
    name: 'Neon Pop',
    background: Color(0xFF18132B),
    surface: Color(0xFF241C42),
    incomingBubble: Color(0xFF332958),
    outgoingBubble: Color(0xFFEC4F9D),
    incomingText: Color(0xFFFFFFFF),
    outgoingText: Color(0xFFFFFFFF),
    header: Color(0xFF241C42),
    headerText: Color(0xFFFFD9F0),
    timestamp: Color(0xFFCAB7DD),
    reactionSurface: Color(0xFF443565),
    isDark: true,
  ),
  ChatThemeStyle(
    id: 'minimal-chat',
    name: 'Minimal Chat',
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFF1F1F1),
    outgoingBubble: Color(0xFF222222),
    incomingText: Color(0xFF1F1F1F),
    outgoingText: Color(0xFFFFFFFF),
    header: Color(0xFFFFFFFF),
    headerText: Color(0xFF1E1E1E),
    timestamp: Color(0xFF8B8B8B),
    reactionSurface: Color(0xFFFFFFFF),
  ),
  ChatThemeStyle(
    id: 'candy-chat',
    name: 'Candy Chat',
    background: Color(0xFFFFF2FA),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFFFDCEC),
    outgoingBubble: Color(0xFF5CCAB4),
    incomingText: Color(0xFF47233A),
    outgoingText: Color(0xFF073D34),
    header: Color(0xFFFFFFFF),
    headerText: Color(0xFF47233A),
    timestamp: Color(0xFF9B7189),
    reactionSurface: Color(0xFFFFFFFF),
  ),
  ChatThemeStyle(
    id: 'dark-mode',
    name: 'Dark Mode',
    background: Color(0xFF202020),
    surface: Color(0xFF2A2A2A),
    incomingBubble: Color(0xFF393939),
    outgoingBubble: Color(0xFFBEE76A),
    incomingText: Color(0xFFF5F5F5),
    outgoingText: Color(0xFF172000),
    header: Color(0xFF2A2A2A),
    headerText: Color(0xFFFFFFFF),
    timestamp: Color(0xFFBFBFBF),
    reactionSurface: Color(0xFF454545),
    isDark: true,
  ),
  ChatThemeStyle(
    id: 'retro-messenger',
    name: 'Retro Messenger',
    background: Color(0xFFF4EFDE),
    surface: Color(0xFFFFFCF2),
    incomingBubble: Color(0xFFD8E0D0),
    outgoingBubble: Color(0xFFE6B76A),
    incomingText: Color(0xFF293026),
    outgoingText: Color(0xFF3B280A),
    header: Color(0xFF476A62),
    headerText: Color(0xFFFFFFFF),
    timestamp: Color(0xFF6B7467),
    reactionSurface: Color(0xFFFFFCF2),
  ),
  ChatThemeStyle(
    id: 'bubble-pro',
    name: 'Bubble Pro',
    background: Color(0xFFF1F7FF),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFDDEAF7),
    outgoingBubble: Color(0xFF2978C6),
    incomingText: Color(0xFF183047),
    outgoingText: Color(0xFFFFFFFF),
    header: Color(0xFFFFFFFF),
    headerText: Color(0xFF183047),
    timestamp: Color(0xFF6F889E),
    reactionSurface: Color(0xFFFFFFFF),
  ),
  ChatThemeStyle(
    id: 'paper-chat',
    name: 'Paper Chat',
    background: Color(0xFFFFFDF5),
    surface: Color(0xFFFFFFFF),
    incomingBubble: Color(0xFFFFF2BB),
    outgoingBubble: Color(0xFFC9E5D2),
    incomingText: Color(0xFF3B3420),
    outgoingText: Color(0xFF173F2C),
    header: Color(0xFFFFFFFF),
    headerText: Color(0xFF3B3420),
    timestamp: Color(0xFF867C5F),
    reactionSurface: Color(0xFFFFFFFF),
  ),
];

ChatThemeStyle themeById(String id) => chatThemes.firstWhere(
      (ChatThemeStyle item) => item.id == id,
      orElse: () => chatThemes.first,
    );
