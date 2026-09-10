import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/built_in_templates.dart';
import '../../models/chat_template.dart';
import '../../providers/template_providers.dart';
import '../widgets/template_card.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(templateSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatTemplate> templates = ref.watch(filteredTemplatesProvider);
    final String category = ref.watch(templateCategoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) => ref.read(templateSearchProvider.notifier).state = value,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search templates',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(templateSearchProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 43,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: templateCategories.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String item = templateCategories[index];
                  return ChoiceChip(
                    label: Text(item),
                    selected: category == item,
                    onSelected: (_) => ref.read(templateCategoryProvider.notifier).state = item,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: templates.isEmpty
                  ? _NoTemplates(
                      onClear: () {
                        _searchController.clear();
                        ref.read(templateSearchProvider.notifier).state = '';
                        ref.read(templateCategoryProvider.notifier).state = 'All';
                      },
                    )
                  : LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final int columns = constraints.maxWidth >= 700 ? 4 : constraints.maxWidth >= 480 ? 3 : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          itemCount: templates.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: columns == 2 ? .75 : .82,
                          ),
                          itemBuilder: (BuildContext context, int index) => TemplateCard(
                            template: templates[index],
                            onTap: () => context.push('/templates/${templates[index].id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTemplates extends StatelessWidget {
  const _NoTemplates({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🔎', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('No templates found.', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Try another search or category.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
}
