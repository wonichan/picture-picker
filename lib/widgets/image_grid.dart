import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
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

/// Individual grid item - displays full image without cropping
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
}
