import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    required this.onAddMessage,
    required this.onMedia,
    required this.onSticker,
    required this.onReaction,
    required this.onStyle,
    required this.onMore,
    super.key,
  });

  final VoidCallback onAddMessage;
  final VoidCallback onMedia;
  final VoidCallback onSticker;
  final VoidCallback onReaction;
  final VoidCallback onStyle;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _ToolButton(icon: Icons.add_comment_rounded, label: 'Message', onTap: onAddMessage),
                  _ToolButton(icon: Icons.image_outlined, label: 'Media', onTap: onMedia),
                  _ToolButton(icon: Icons.emoji_emotions_outlined, label: 'Stickers', onTap: onSticker),
                  _ToolButton(icon: Icons.add_reaction_outlined, label: 'Reaction', onTap: onReaction),
                  _ToolButton(icon: Icons.palette_outlined, label: 'Style', onTap: onStyle),
                  _ToolButton(icon: Icons.more_horiz_rounded, label: 'More', onTap: onMore),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 22),
                  const SizedBox(height: 3),
                  Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      );
}
