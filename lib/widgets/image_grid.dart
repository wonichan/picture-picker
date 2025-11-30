import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/image_file_info.dart';
import '../providers/image_picker_provider.dart';

/// High-performance image grid with masonry layout
/// Each image displays with its natural aspect ratio!
class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImagePickerProvider>(
      builder: (context, provider, child) {
        if (provider.sourceFolderPath == null) {
          return _buildEmptyState();
        }

        if (provider.isScanning && provider.images.isEmpty) {
          return _buildScanningState();
        }

        if (provider.images.isEmpty) {
          return _buildNoImagesState();
        }

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, provider),

            // Masonry Grid - dynamic columns and aspect ratios
            Expanded(
              child: MasonryGridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: provider.gridColumnCount, // Dynamic!
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: provider.images.length,
                itemBuilder: (context, index) {
                  final image = provider.images[index];
                  final isSelected = provider.selectedImages.contains(image);
                  return _ImageGridItem(
                    imageInfo: image,
                    isSelected: isSelected,
                    onTap: () => provider.toggleImageSelection(image),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, ImagePickerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Text(
            'Images (sorted by size)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // Grid size slider
          Icon(Icons.view_module, size: 16, color: Colors.grey.shade600),
          SizedBox(
            width: 120,
            child: Slider(
              value: provider.gridColumnCount.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '${provider.gridColumnCount} columns',
              onChanged: (value) {
                provider.setGridColumnCount(value.round());
              },
            ),
          ),
          Icon(Icons.grid_view, size: 16, color: Colors.grey.shade600),
          const Spacer(),
          TextButton.icon(
            onPressed: provider.hasSelection
                ? () => provider.clearSelection()
                : () => provider.selectAll(),
            icon: Icon(
              provider.hasSelection ? Icons.deselect : Icons.select_all,
              size: 18,
            ),
            label: Text(provider.hasSelection ? 'Clear' : 'Select All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Select a folder to start',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Scanning folder...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No images found in this folder',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Individual grid item with right-click context menu
class _ImageGridItem extends StatelessWidget {
  final ImageFileInfo imageInfo;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImageGridItem({
    required this.imageInfo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown: (details) {
        // Show context menu on right-click
        _showContextMenu(context, details.globalPosition);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail - natural aspect ratio, no cropping
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  child: Image.file(
                    imageInfo.file,
                    fit: BoxFit.contain, // Show full image!
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            // File info
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imageInfo.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageInfo.formattedSize,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show context menu on right-click
  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.open_in_new, size: 18),
              SizedBox(width: 8),
              Text('Open File'),
            ],
          ),
          onTap: () => _openFile(),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Show in Folder'),
            ],
          ),
          onTap: () => _showInFolder(),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete File', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFile(context),
        ),
      ],
    );
  }

  /// Open file with default program
  void _openFile() async {
    try {
      await Process.run('cmd', ['/c', 'start', '', imageInfo.path]);
    } catch (e) {
      print('Failed to open file: $e');
    }
  }

  /// Open file location in Explorer
  void _showInFolder() async {
    try {
      await Process.run('explorer', ['/select,', imageInfo.path]);
    } catch (e) {
      print('Failed to show in folder: $e');
    }
  }

  /// Delete file with confirmation
  void _deleteFile(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete this file?\n\n${imageInfo.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete the file
        await imageInfo.file.delete();

        // Remove from provider's list
        if (context.mounted) {
          final provider = Provider.of<ImagePickerProvider>(
            context,
            listen: false,
          );
          provider.removeImage(imageInfo);
        }
      } catch (e) {
        // Show error dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Failed'),
              content: Text('Failed to delete file:\n$e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
