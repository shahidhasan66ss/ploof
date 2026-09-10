import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../editor/models/chat_models.dart';
import '../data/creation_storage_service.dart';

final creationStorageProvider = Provider<CreationStorageService>(
  (Ref ref) => CreationStorageService(),
);

final creationsProvider = StateNotifierProvider<CreationsNotifier, CreationsState>(
  (Ref ref) => CreationsNotifier(ref.read(creationStorageProvider)),
);

class CreationsState {
  const CreationsState({
    this.projects = const <ChatProject>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatProject> projects;
  final bool isLoading;
  final String? errorMessage;

  CreationsState copyWith({
    List<ChatProject>? projects,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CreationsState(
        projects: projects ?? this.projects,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

class CreationsNotifier extends StateNotifier<CreationsState> {
  CreationsNotifier(this._storage) : super(const CreationsState());

  final CreationStorageService _storage;
  final Uuid _uuid = const Uuid();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final List<ChatProject> projects = await _storage.loadAllCreations();
    state = state.copyWith(projects: projects, isLoading: false);
  }

  Future<void> save(ChatProject project) async {
    final ChatProject saved = project.copyWith(updatedAt: DateTime.now());
    try {
      await _storage.saveCreation(saved);
      final List<ChatProject> next = <ChatProject>[saved,
        ...state.projects.where((ChatProject item) => item.id != saved.id),
      ]..sort((ChatProject a, ChatProject b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(projects: next, clearError: true);
    } on CreationStorageException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      rethrow;
    }
  }

  Future<ChatProject?> getById(String id) async {
    for (final ChatProject project in state.projects) {
      if (project.id == id) return project;
    }
    return _storage.loadCreation(id);
  }

  Future<ChatProject> duplicate(ChatProject project) async {
    final DateTime now = DateTime.now();
    final ChatProject copy = project.copyWith(
      id: _uuid.v4(),
      name: '${project.name} copy',
      createdAt: now,
      updatedAt: now,
    );
    await save(copy);
    return copy;
  }

  Future<void> rename(ChatProject project, String name) async {
    final String safeName = name.trim().isEmpty ? 'Untitled chat' : name.trim();
    await save(project.copyWith(name: safeName));
  }

  Future<void> delete(String id) async {
    try {
      await _storage.deleteCreation(id);
      state = state.copyWith(
        projects: state.projects.where((ChatProject item) => item.id != id).toList(),
        clearError: true,
      );
    } on CreationStorageException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      rethrow;
    }
  }
}
