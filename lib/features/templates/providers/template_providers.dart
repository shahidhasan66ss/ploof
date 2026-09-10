import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/built_in_templates.dart';
import '../models/chat_template.dart';

final templateCatalogProvider = Provider<List<ChatTemplate>>(
  (Ref ref) => List<ChatTemplate>.unmodifiable(builtInTemplates),
);

final templateSearchProvider = StateProvider<String>((Ref ref) => '');
final templateCategoryProvider = StateProvider<String>((Ref ref) => 'All');

final filteredTemplatesProvider = Provider<List<ChatTemplate>>((Ref ref) {
  final String query = ref.watch(templateSearchProvider).trim().toLowerCase();
  final String category = ref.watch(templateCategoryProvider);
  return ref.watch(templateCatalogProvider).where((ChatTemplate template) {
    final bool matchesCategory = category == 'All' || template.category == category;
    final bool matchesQuery = query.isEmpty ||
        template.name.toLowerCase().contains(query) ||
        template.description.toLowerCase().contains(query) ||
        template.category.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList(growable: false);
});

final templateByIdProvider = Provider.family<ChatTemplate?, String>((Ref ref, String id) {
  for (final ChatTemplate template in ref.watch(templateCatalogProvider)) {
    if (template.id == id) return template;
  }
  return null;
});
