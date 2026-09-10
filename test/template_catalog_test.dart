import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatpop/features/templates/providers/template_providers.dart';

void main() {
  test('catalog has at least twenty-five offline templates', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(templateCatalogProvider), hasLength(greaterThanOrEqualTo(25)));
  });

  test('category and query filters operate locally', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(templateCategoryProvider.notifier).state = 'Family';
    container.read(templateSearchProvider.notifier).state = 'dad';

    final results = container.read(filteredTemplatesProvider);
    expect(results, hasLength(1));
    expect(results.single.id, 'dad-has-questions');
  });
}
