import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../editor/models/chat_models.dart';
import '../../../editor/presentation/widgets/chat_renderer.dart';
import '../../../editor/providers/editor_provider.dart';
import '../../providers/creation_provider.dart';

class CreationsScreen extends ConsumerStatefulWidget {
  const CreationsScreen({super.key});

  @override
  ConsumerState<CreationsScreen> createState() => _CreationsScreenState();
}

class _CreationsScreenState extends ConsumerState<CreationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(creationsProvider).projects.isEmpty) ref.read(creationsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final creations = ref.watch(creationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Creations')),
      body: SafeArea(
        top: false,
        child: creations.isLoading && creations.projects.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : creations.projects.isEmpty
                ? _EmptyCreations(onCreate: () => context.push('/create'))
                : RefreshIndicator(
                    onRefresh: () => ref.read(creationsProvider.notifier).load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      itemCount: creations.projects.length,
                      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) => _CreationCard(
                        project: creations.projects[index],
                        onOpen: () => context.push('/creations/${creations.projects[index].id}'),
                        onAction: (String action) => _handleAction(action, creations.projects[index]),
                      ),
                    ),
                  ),
      ),
    );
  }

  Future<void> _handleAction(String action, ChatProject project) async {
    switch (action) {
      case 'open':
        context.push('/creations/${project.id}');
        return;
      case 'duplicate':
        final ChatProject copy = await ref.read(creationsProvider.notifier).duplicate(project);
        if (mounted) {
          _showMessage('Duplicated!');
          context.push('/creations/${copy.id}');
        }
        return;
      case 'rename':
        await _rename(project);
        return;
      case 'export':
        ref.read(editorProvider.notifier).initializeProject(project);
        if (mounted) context.push('/preview');
        return;
      case 'delete':
        await _delete(project);
        return;
    }
  }

  Future<void> _rename(ChatProject project) async {
    final TextEditingController controller = TextEditingController(text: project.name);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename creation'),
        content: TextField(controller: controller, autofocus: true, maxLength: 60),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    try {
      await ref.read(creationsProvider.notifier).rename(project, result);
      if (mounted) _showMessage('Renamed.');
    } catch (_) {
      if (mounted) _showMessage('Could not rename this chat.');
    }
  }

  Future<void> _delete(ChatProject project) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this creation?'),
        content: Text('“${project.name}” will be removed from this device.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(creationsProvider.notifier).delete(project.id);
      if (mounted) _showMessage('Deleted.');
    } catch (_) {
      if (mounted) _showMessage('Could not delete this chat.');
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _CreationCard extends StatelessWidget {
  const _CreationCard({required this.project, required this.onOpen, required this.onAction});
  final ChatProject project;
  final VoidCallback onOpen;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 162,
            child: Row(
              children: <Widget>[
                SizedBox(width: 132, child: Padding(padding: const EdgeInsets.all(12), child: ChatRenderer(project: project, compact: true))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 18, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(
                          project.templateId == null ? 'Original chat' : 'Template chat',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 3),
                        Text(DateFormat.MMMd().add_jm().format(project.updatedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const Spacer(),
                        Text('Open to edit', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Creation actions',
                  onSelected: onAction,
                  itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'open', child: Text('Open')),
                    PopupMenuItem<String>(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
                    PopupMenuItem<String>(value: 'export', child: Text('Export & share')),
                    PopupMenuDivider(),
                    PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyCreations extends StatelessWidget {
  const _EmptyCreations({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🪩', style: TextStyle(fontSize: 45)),
              const SizedBox(height: 12),
              Text('Nothing funny yet.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Create your first chat and start the chaos.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_comment_rounded), label: const Text('Create a Chat')),
            ],
          ),
        ),
      );
