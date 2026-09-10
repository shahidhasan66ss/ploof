import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/brand_mark.dart';
import '../../../creations/providers/creation_provider.dart';
import '../../../editor/presentation/widgets/chat_renderer.dart';
import '../../../templates/models/chat_template.dart';
import '../../../templates/providers/template_providers.dart';
import '../../../templates/presentation/widgets/template_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(creationsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ChatTemplate> templates = ref.watch(templateCatalogProvider);
    final creations = ref.watch(creationsProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(creationsProvider.notifier).load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: <Widget>[
                      const BrandMark(),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _HeroCard(onCreate: () => _showStartSheet(context)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeading(
                    title: 'Start with a vibe',
                    action: 'See all',
                    onAction: () => context.go('/templates'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                    itemCount: templates.length < 8 ? templates.length : 8,
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext context, int index) => SizedBox(
                      width: 160,
                      child: TemplateCard(
                        template: templates[index],
                        compact: true,
                        onTap: () => context.push('/templates/${templates[index].id}'),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeading(title: 'Popular reactions', action: 'Add one', onAction: () => _showStartSheet(context)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(child: const _ReactionPack()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeading(
                    title: 'Your recent creations',
                    action: creations.projects.isEmpty ? null : 'View all',
                    onAction: () => context.go('/creations'),
                  ),
                ),
              ),
              if (creations.isLoading && creations.projects.isEmpty)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())))
              else if (creations.projects.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyRecent(onCreate: () => _showStartSheet(context)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: creations.projects.length > 2 ? 2 : creations.projects.length,
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final project = creations.projects[index];
                      return SizedBox(
                        height: 150,
                        child: Card(
                          child: InkWell(
                            onTap: () => context.push('/creations/${project.id}'),
                            borderRadius: BorderRadius.circular(24),
                            child: Row(
                              children: <Widget>[
                                SizedBox(width: 124, child: Padding(padding: const EdgeInsets.all(10), child: ChatRenderer(project: project, compact: true))),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 18, 18, 18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 6),
                                        Text(
                                          project.templateId == null ? 'Made from scratch' : 'Template creation',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                        const Spacer(),
                                        Text('Open and keep creating', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Ready to cause some harmless chaos?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Make it funny — and keep it clearly fictional.'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/create');
                },
                icon: const Icon(Icons.add_comment_rounded),
                label: const Text('Start blank'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/templates');
                },
                icon: const Icon(Icons.auto_awesome_mosaic_rounded),
                label: const Text('Use a template'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(.74), borderRadius: BorderRadius.circular(100)),
            child: Text('OFFLINE • FICTIONAL • FUN', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: .5)),
          ),
          const SizedBox(height: 18),
          Text('Make a chat.\nMake it hilarious.', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text('Create fictional conversations, add reactions, and share the chaos.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_comment_rounded), label: const Text('Create a Chat')),
          const SizedBox(height: 10),
          TextButton.icon(onPressed: () => context.go('/templates'), icon: const Icon(Icons.grid_view_rounded), label: const Text('Browse Templates')),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class _ReactionPack extends StatelessWidget {
  const _ReactionPack();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              for (final String emoji in <String>['😂', '💀', '😭', '😳', '🔥', '✨'])
                Expanded(child: Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28))),
            ],
          ),
        ),
      );
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('🎈', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text('Nothing funny yet.', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Your creations will appear here. Create your first chat and start the chaos.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onCreate, child: const Text('Create your first one')),
            ],
          ),
        ),
      );
