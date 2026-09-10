import '../models/sticker.dart';

const List<String> stickerCategories = <String>[
  'All', 'LOL', 'Reaction', 'Shock', 'Roast', 'Love', 'Chaos', 'Sad', 'Confused', 'Celebration', 'Memes'
];

/// Emoji-led original sticker labels keep the starter pack compact and offline.
const List<StickerItem> stickers = <StickerItem>[
  StickerItem(id: 'laugh', emoji: '😂', label: 'Wheezing', category: 'LOL'),
  StickerItem(id: 'skull', emoji: '💀', label: 'Gone', category: 'LOL'),
  StickerItem(id: 'cry', emoji: '😭', label: 'Too much', category: 'Sad'),
  StickerItem(id: 'shock', emoji: '😳', label: 'Whoa', category: 'Shock'),
  StickerItem(id: 'hmm', emoji: '🤨', label: 'Hmm', category: 'Confused'),
  StickerItem(id: 'neutral', emoji: '😐', label: 'Blank stare', category: 'Reaction'),
  StickerItem(id: 'eyes', emoji: '👀', label: 'Watching', category: 'Reaction'),
  StickerItem(id: 'fire', emoji: '🔥', label: 'Fire', category: 'Roast'),
  StickerItem(id: 'mind', emoji: '🤯', label: 'Mind blown', category: 'Shock'),
  StickerItem(id: 'upside', emoji: '🙃', label: 'Sure', category: 'Memes'),
  StickerItem(id: 'clap', emoji: '👏', label: 'Applause', category: 'Celebration'),
  StickerItem(id: 'nails', emoji: '💅', label: 'Polished', category: 'Roast'),
  StickerItem(id: 'melt', emoji: '🫠', label: 'Melting', category: 'Sad'),
  StickerItem(id: 'clown', emoji: '🤡', label: 'Clown moment', category: 'Memes'),
  StickerItem(id: 'alarm', emoji: '🚨', label: 'Alert', category: 'Chaos'),
  StickerItem(id: 'sparkle', emoji: '✨', label: 'Sparkles', category: 'Celebration'),
  StickerItem(id: 'heart', emoji: '🫶', label: 'Heart hands', category: 'Love'),
  StickerItem(id: 'party', emoji: '🥳', label: 'Party', category: 'Celebration'),
  StickerItem(id: 'rain', emoji: '🌧️', label: 'Tiny raincloud', category: 'Sad'),
  StickerItem(id: 'spin', emoji: '🌀', label: 'Spiraling', category: 'Chaos'),
];

const List<String> reactionEmojis = <String>['😂', '❤️', '🔥', '😳', '😭', '👍', '👎', '💀', '😮', '🤔'];
