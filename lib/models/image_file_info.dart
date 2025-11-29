import 'dart:io';

/// Image file information model
/// Optimized for memory efficiency - only stores essential data
class ImageFileInfo implements Comparable<ImageFileInfo> {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;

  ImageFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
  });

  /// Create from FileSystemEntity with minimal memory footprint
  factory ImageFileInfo.fromFile(File file) {
    final stat = file.statSync();
    return ImageFileInfo(
      path: file.path,
      name: file.uri.pathSegments.last,
      sizeBytes: stat.size,
      lastModified: stat.modified,
    );
  }

  /// Get file as File object (lazy)
  File get file => File(path);

  /// Human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file still exists (for safety)
  bool get exists => file.existsSync();

  /// Compare by size (descending) - for sorting
  @override
  int compareTo(ImageFileInfo other) {
    return other.sizeBytes.compareTo(sizeBytes); // Larger files first
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageFileInfo && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'ImageFileInfo($name, $formattedSize)';
}
