import 'dart:io';
import '../models/folder_info.dart';

/// Service for managing target folders with recursive support
class FolderService {
  /// Get all folders recursively from a parent directory
  static List<FolderInfo> getSubfoldersRecursive(
    String parentPath, {
    int maxDepth = 3,
  }) {
    try {
      final parentDir = Directory(parentPath);

      if (!parentDir.existsSync()) {
        return [];
      }

      final folders = <FolderInfo>[];
      _scanDirectory(parentDir, folders, depth: 0, maxDepth: maxDepth);

      return folders;
    } catch (e) {
      print('[FolderService] Error scanning folders: $e');
      return [];
    }
  }

  /// Recursive scanning helper
  static void _scanDirectory(
    Directory dir,
    List<FolderInfo> folders, {
    required int depth,
    required int maxDepth,
  }) {
    if (depth > maxDepth) return;

    try {
      final entities = dir.listSync();
      final subdirs = entities.whereType<Directory>().toList();

      for (final subdir in subdirs) {
        // Check if this folder has children
        final hasChildren = _hasSubdirectories(subdir);

        // Add current folder
        folders.add(
          FolderInfo.fromDirectory(
            subdir,
            depth: depth,
            hasChildren: hasChildren,
          ),
        );

        // Recursively scan children
        if (hasChildren && depth < maxDepth) {
          _scanDirectory(subdir, folders, depth: depth + 1, maxDepth: maxDepth);
        }
      }

      // Sort by path to maintain tree order
      folders.sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      // Ignore permission errors on individual folders
    }
  }

  /// Check if directory has subdirectories
  static bool _hasSubdirectories(Directory dir) {
    try {
      final entities = dir.listSync();
      return entities.any((e) => e is Directory);
    } catch (e) {
      return false;
    }
  }

  /// Get all subdirectories from a parent directory (non-recursive, legacy)
  static List<FolderInfo> getSubfolders(String parentPath) {
    try {
      final parentDir = Directory(parentPath);

      if (!parentDir.existsSync()) {
        return [];
      }

      final entities = parentDir.listSync();
      final folders = <FolderInfo>[];

      for (final entity in entities) {
        if (entity is Directory) {
          folders.add(FolderInfo.fromDirectory(entity));
        }
      }

      // Sort alphabetically
      folders.sort((a, b) => a.name.compareTo(b.name));

      return folders;
    } catch (e) {
      return [];
    }
  }

  /// Create new folder in parent directory
  static FolderInfo? createFolder(String parentPath, String folderName) {
    try {
      final newFolderPath = '$parentPath${Platform.pathSeparator}$folderName';
      final newDir = Directory(newFolderPath);

      if (newDir.existsSync()) {
        return null; // Already exists
      }

      newDir.createSync(recursive: true);
      return FolderInfo.fromDirectory(newDir);
    } catch (e) {
      return null;
    }
  }

  /// Check if directory exists and is accessible
  static bool isValidDirectory(String path) {
    try {
      final dir = Directory(path);
      return dir.existsSync();
    } catch (e) {
      return false;
    }
  }
}
