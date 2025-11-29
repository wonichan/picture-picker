import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/image_picker_provider.dart';

/// Target folder list with tree hierarchy support
class TargetFolderList extends StatelessWidget {
  const TargetFolderList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImagePickerProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with folder selection button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Target Folders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Button to select root folder
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: 'Select Target Root Folder',
                      );
                      if (result != null && context.mounted) {
                        provider.setTargetRootPath(result);
                      }
                    },
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => provider.loadTargetFolders(),
                    tooltip: 'Refresh folders',
                  ),
                ],
              ),
            ),

            // Folder tree
            Expanded(
              child: provider.targetFolders.isEmpty
                  ? _buildEmptyState(provider.targetRootPath)
                  : ListView.builder(
                      itemCount: provider.targetFolders.length,
                      itemBuilder: (context, index) {
                        final folder = provider.targetFolders[index];
                        final isSelected =
                            provider.selectedTargetFolder == folder;

                        // Calculate indentation
                        final indentAmount = folder.depth.toDouble() * 20.0;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.deepPurple.shade50,
                          contentPadding: EdgeInsets.only(
                            left: 16.0 + indentAmount,
                            right: 16.0,
                          ),
                          leading: Icon(
                            folder.hasChildren
                                ? Icons.folder_open
                                : Icons.folder,
                            color: isSelected
                                ? Colors.deepPurple
                                : (folder.depth > 0
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600),
                            size: 20,
                          ),
                          title: Text(
                            folder.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: folder.depth > 0 ? 13.0 : 14.0,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.deepPurple,
                                  size: 20,
                                )
                              : null,
                          onTap: () => provider.selectTargetFolder(folder),
                        );
                      },
                    ),
            ),

            // Footer with path
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Root Path:',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.targetRootPath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String rootPath) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No folders found in:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              rootPath,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Click "Change" to select a different folder',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
