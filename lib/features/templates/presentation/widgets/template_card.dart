import 'package:flutter/material.dart';

import '../../models/chat_template.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    required this.template,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final ChatTemplate template;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${template.name}, ${template.category}. ${template.description}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(compact ? 13 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: compact ? 39 : 50,
                  height: compact ? 39 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(template.accentEmoji, style: TextStyle(fontSize: compact ? 21 : 28)),
                ),
                const Spacer(),
                Text(
                  template.category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.name,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
