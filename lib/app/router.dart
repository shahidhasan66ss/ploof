import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/screens/about_screen.dart';
import '../features/creations/presentation/screens/creations_screen.dart';
import '../features/editor/presentation/screens/editor_screen.dart';
import '../features/export/presentation/screens/preview_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/templates/presentation/screens/template_detail_screen.dart';
import '../features/templates/presentation/screens/templates_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) => AppShell(location: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (BuildContext context, GoRouterState state) => const HomeScreen()),
        GoRoute(path: '/templates', builder: (BuildContext context, GoRouterState state) => const TemplatesScreen()),
        GoRoute(path: '/creations', builder: (BuildContext context, GoRouterState state) => const CreationsScreen()),
        GoRoute(path: '/settings', builder: (BuildContext context, GoRouterState state) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/templates/:id',
      builder: (BuildContext context, GoRouterState state) => TemplateDetailScreen(templateId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/create',
      builder: (BuildContext context, GoRouterState state) => const EditorScreen(key: ValueKey<String>('blank-editor')),
    ),
    GoRoute(
      path: '/create/:templateId',
      builder: (BuildContext context, GoRouterState state) => EditorScreen(
        key: ValueKey<String>('template-${state.pathParameters['templateId']}'),
        templateId: state.pathParameters['templateId'],
      ),
    ),
    GoRoute(path: '/preview', builder: (BuildContext context, GoRouterState state) => const PreviewScreen()),
    GoRoute(
      path: '/creations/:id',
      builder: (BuildContext context, GoRouterState state) => EditorScreen(
        key: ValueKey<String>('creation-${state.pathParameters['id']}'),
        creationId: state.pathParameters['id'],
      ),
    ),
    GoRoute(path: '/about', builder: (BuildContext context, GoRouterState state) => const AboutScreen()),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.home_rounded),
        label: const Text('Back to ChatPop'),
      ),
    ),
  ),
);

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int index = _indexFor(location);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Create a chat',
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Create'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) {
          switch (value) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/templates');
              break;
            case 2:
              context.go('/creations');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Templates'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark_rounded), label: 'Creations'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  int _indexFor(String path) {
    if (path.startsWith('/templates')) return 1;
    if (path.startsWith('/creations')) return 2;
    if (path.startsWith('/settings')) return 3;
    return 0;
  }
}
