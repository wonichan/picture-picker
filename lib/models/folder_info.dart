import 'dart:io';

/// Target folder information with hierarchy support
class FolderInfo {
  final String path;
  final String name;
  final int depth; // 文件夹深度，用于缩进显示
  final bool hasChildren; // 是否有子文件夹

  FolderInfo({
    required this.path,
    required this.name,
    this.depth = 0,
    this.hasChildren = false,
  });

  /// Create from directory
  factory FolderInfo.fromDirectory(
    Directory dir, {
    int depth = 0,
    bool hasChildren = false,
  }) {
    return FolderInfo(
      path: dir.path,
      name: dir.uri.pathSegments[dir.uri.pathSegments.length - 2],
      depth: depth,
      hasChildren: hasChildren,
    );
  }

  Directory get directory => Directory(path);

  bool get exists => directory.existsSync();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderInfo && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'FolderInfo($name, depth: $depth)';
}
