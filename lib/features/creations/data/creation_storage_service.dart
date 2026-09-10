import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../editor/models/chat_models.dart';

class CreationStorageException implements Exception {
  const CreationStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// File-per-project storage. JSON stays small; selected image paths are stored
/// by reference so a project never embeds a huge base64 payload.
class CreationStorageService {
  Future<Directory> _directory() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory directory = Directory('${documents.path}/${AppConstants.creationsDirectory}');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _fileFor(String id) async {
    final Directory directory = await _directory();
    return File('${directory.path}/$id.json');
  }

  Future<void> saveCreation(ChatProject project) async {
    try {
      final File target = await _fileFor(project.id);
      final File temporary = File('${target.path}.tmp');
      await temporary.writeAsString(project.encode(), flush: true);
      await temporary.copy(target.path);
      if (await temporary.exists()) await temporary.delete();
    } on FileSystemException catch (error) {
      throw CreationStorageException('Could not save this chat. ${error.message}');
    } catch (_) {
      throw const CreationStorageException('Could not save this chat right now.');
    }
  }

  Future<ChatProject?> loadCreation(String id) async {
    try {
      final File file = await _fileFor(id);
      if (!await file.exists()) return null;
      return ChatProject.decode(await file.readAsString());
    } catch (_) {
      // A bad single project should not make the gallery unusable.
      return null;
    }
  }

  Future<List<ChatProject>> loadAllCreations() async {
    try {
      final Directory directory = await _directory();
      final List<ChatProject> projects = <ChatProject>[];
      await for (final FileSystemEntity entity in directory.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          projects.add(ChatProject.decode(await entity.readAsString()));
        } catch (_) {
          // Corrupt files are ignored and can be deleted by the user in Files.
        }
      }
      projects.sort((ChatProject a, ChatProject b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (_) {
      return <ChatProject>[];
    }
  }

  /// Copies picker output into app documents so gallery-cache eviction cannot
  /// break a saved project later. It is called only after the user picks media.
  Future<String> persistMedia(String sourcePath) async {
    try {
      final File source = File(sourcePath);
      if (!await source.exists()) {
        throw const CreationStorageException('That image is no longer available.');
      }
      final Directory root = await _directory();
      final Directory media = Directory('${root.path}/media');
      if (!await media.exists()) await media.create(recursive: true);
      final String name = source.uri.pathSegments.isEmpty ? 'image.jpg' : source.uri.pathSegments.last;
      final String extension = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '.jpg';
      final File destination = File('${media.path}/media-${DateTime.now().microsecondsSinceEpoch}$extension');
      await source.copy(destination.path);
      return destination.path;
    } on CreationStorageException {
      rethrow;
    } on FileSystemException catch (error) {
      throw CreationStorageException('Could not keep that image. ${error.message}');
    } catch (_) {
      throw const CreationStorageException('Could not keep that image.');
    }
  }

  Future<void> deleteCreation(String id) async {
    try {
      final File file = await _fileFor(id);
      ChatProject? deleted;
      if (await file.exists()) {
        try {
          deleted = ChatProject.decode(await file.readAsString());
        } catch (_) {
          // The JSON itself can still be deleted if it was corrupt.
        }
        await file.delete();
      }
      if (deleted != null) await _removeUnreferencedMedia(deleted);
    } on FileSystemException catch (error) {
      throw CreationStorageException('Could not delete this chat. ${error.message}');
    } catch (_) {
      throw const CreationStorageException('Could not delete this chat right now.');
    }
  }

  Future<void> _removeUnreferencedMedia(ChatProject deleted) async {
    final Set<String> candidates = deleted.messages
        .map((ChatMessage message) => message.mediaPath)
        .whereType<String>()
        .toSet();
    if (candidates.isEmpty) return;
    final Set<String> usedByOtherProjects = <String>{};
    for (final ChatProject project in await loadAllCreations()) {
      usedByOtherProjects.addAll(
        project.messages.map((ChatMessage message) => message.mediaPath).whereType<String>(),
      );
    }
    final Directory root = await _directory();
    final String managedMediaPath = '${root.path}/media${Platform.pathSeparator}';
    for (final String path in candidates.difference(usedByOtherProjects)) {
      if (!path.startsWith(managedMediaPath)) continue;
      final File image = File(path);
      if (await image.exists()) await image.delete();
    }
  }

  Future<void> renameCreation(ChatProject project, String name) {
    return saveCreation(project.copyWith(name: name, updatedAt: DateTime.now()));
  }
}
