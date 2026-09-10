import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/template_project_factory.dart';
import '../../models/chat_template.dart';
import '../../providers/template_providers.dart';
import '../../../editor/presentation/widgets/chat_renderer.dart';

class TemplateDetailScreen extends ConsumerWidget {
  const TemplateDetailScreen({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatTemplate? template = ref.watch(templateByIdProvider(templateId));
    if (template == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.broken_image_outlined, size: 48),
                const SizedBox(height: 12),
                Text('That template wandered off.', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/templates'), child: const Text('Back to templates')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Template preview')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Hero(
                  tag: 'template-$templateId',
                  child: ChatRenderer(project: templatePreviewProject(template)),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(template.category.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text(template.accentEmoji, style: const TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 8),
              Text(template.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(template.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/create/$templateId'),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Use Template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
