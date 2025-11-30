import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/image_file_info.dart';
import '../models/operation_result.dart';

/// Service for file operations (move/copy)
/// Built with proper error handling - not like those amateur implementations!
class FileOperationService {
  /// Move file to target directory
  /// Fixed for cross-drive moves on Windows!
  static Future<OperationResult> moveFile(
    ImageFileInfo imageInfo,
    String targetDirectoryPath,
  ) async {
    try {
      final sourceFile = imageInfo.file;

      // Validate source exists
      if (!sourceFile.existsSync()) {
        return OperationResult.failure(
          imageInfo.path,
          'Source file no longer exists',
        );
      }

      // Ensure target directory exists
      final targetDir = Directory(targetDirectoryPath);
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // Build target path
      final targetPath = path.join(targetDirectoryPath, imageInfo.name);

      // Handle name collision
      final finalTargetPath = _resolveNameCollision(targetPath);

      // Try rename first (fast, but only works on same drive)
      // If it fails, use copy+delete (slower but works across drives)
      try {
        await sourceFile.rename(finalTargetPath);
        print('[MOVE] Renamed: ${imageInfo.name}');
      } catch (e) {
        // Rename failed (likely cross-drive), use copy+delete
        print('[MOVE] Rename failed, using copy+delete: $e');
        await sourceFile.copy(finalTargetPath);
        await sourceFile.delete();
        print('[MOVE] Copy+delete successful: ${imageInfo.name}');
      }

      return OperationResult.success(imageInfo.path, finalTargetPath);
    } catch (e, stackTrace) {
      // Detailed error logging
      print('[ERROR] Move failed for ${imageInfo.name}:');
      print('  Error: $e');
      print('  Stack: $stackTrace');
      return OperationResult.failure(imageInfo.path, e.toString());
    }
  }

  /// Copy file to target directory
  static Future<OperationResult> copyFile(
    ImageFileInfo imageInfo,
    String targetDirectoryPath,
  ) async {
    try {
      final sourceFile = imageInfo.file;

      // Validate source exists
      if (!sourceFile.existsSync()) {
        return OperationResult.failure(
          imageInfo.path,
          'Source file no longer exists',
        );
      }

      // Ensure target directory exists
      final targetDir = Directory(targetDirectoryPath);
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // Build target path
      final targetPath = path.join(targetDirectoryPath, imageInfo.name);

      // Handle name collision
      final finalTargetPath = _resolveNameCollision(targetPath);

      // Perform copy operation
      await sourceFile.copy(finalTargetPath);

      return OperationResult.success(imageInfo.path, finalTargetPath);
    } catch (e) {
      return OperationResult.failure(
        imageInfo.path,
        'Copy failed: ${e.toString()}',
      );
    }
  }

  /// Resolve file name by adding timestamp suffix
  /// e.g., image.jpg -> image_20251130_171639.jpg
  static String _resolveNameCollision(String targetPath) {
    final dir = path.dirname(targetPath);
    final basename = path.basenameWithoutExtension(targetPath);
    final extension = path.extension(targetPath);

    // Generate timestamp: YYYYMMDD_HHMMSS
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // Build new filename with timestamp
    final newPath = path.join(dir, '${basename}_$timestamp$extension');

    // If timestamp collision (extremely rare), add milliseconds
    if (File(newPath).existsSync()) {
      final timestampWithMs =
          '${timestamp}_${now.millisecond.toString().padLeft(3, '0')}';
      return path.join(dir, '${basename}_$timestampWithMs$extension');
    }

    return newPath;
  }

  /// Batch move files - with error collection
  static Future<List<OperationResult>> moveBatch(
    List<ImageFileInfo> images,
    String targetDirectoryPath,
  ) async {
    final results = <OperationResult>[];

    for (final image in images) {
      final result = await moveFile(image, targetDirectoryPath);
      results.add(result);
    }

    return results;
  }

  /// Batch copy files - with error collection
  static Future<List<OperationResult>> copyBatch(
    List<ImageFileInfo> images,
    String targetDirectoryPath,
  ) async {
    final results = <OperationResult>[];

    for (final image in images) {
      final result = await copyFile(image, targetDirectoryPath);
      results.add(result);
    }

    return results;
  }
}
