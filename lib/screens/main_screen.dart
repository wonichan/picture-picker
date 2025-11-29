import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/image_picker_provider.dart';
import '../widgets/image_grid.dart';
import '../widgets/target_folder_list.dart';
import '../widgets/operation_buttons.dart';

/// Main screen - professional layout
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Picture Picker - Professional Image Classifier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Top: Source folder selector
          _buildSourceFolderSelector(context),

          const Divider(height: 1),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left: Image grid (60% width)
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const ImageGrid(),
                  ),
                ),

                // Center: Operation buttons (10% width)
                const SizedBox(width: 120, child: OperationButtons()),

                // Right: Target folder list (30% width)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const TargetFolderList(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom: Status bar
          _buildStatusBar(context),
        ],
      ),
    );
  }

  Widget _buildSourceFolderSelector(BuildContext context) {
    return Consumer<ImagePickerProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Source Folder:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.sourceFolderPath ?? 'No folder selected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: provider.sourceFolderPath != null
                            ? Colors.black87
                            : Colors.black38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: provider.isScanning
                    ? null
                    : () => _selectFolder(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return Consumer<ImagePickerProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              if (provider.isScanning)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Scanning...'),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.image, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.totalImagesFound} images found',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(width: 32),
              if (provider.hasSelection) ...[
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${provider.selectionCount} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
              const Spacer(),
              if (provider.isOperating)
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: provider.operationProgressPercent,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${provider.operationProgress}/${provider.operationTotal}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Source Folder',
    );

    if (result != null && context.mounted) {
      context.read<ImagePickerProvider>().setSourceFolder(result);
    }
  }
}
