import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_picker_provider.dart';

/// Operation buttons (Move/Copy) in the center column
class OperationButtons extends StatelessWidget {
  const OperationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImagePickerProvider>(
      builder: (context, provider, child) {
        final canOperate =
            provider.hasSelection &&
            provider.selectedTargetFolder != null &&
            !provider.isOperating;

        return Container(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Move button
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: canOperate
                      ? () => _handleMove(context, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.drive_file_move, size: 28),
                      SizedBox(height: 8),
                      Text(
                        'MOVE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Copy button
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: canOperate
                      ? () => _handleCopy(context, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.file_copy, size: 28),
                      SizedBox(height: 8),
                      Text(
                        'COPY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info text
              if (!canOperate)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    provider.isOperating
                        ? 'Processing...'
                        : !provider.hasSelection
                        ? 'Select images first'
                        : 'Select target folder',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMove(
    BuildContext context,
    ImagePickerProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Move Files',
      'Move ${provider.selectionCount} file(s) to "${provider.selectedTargetFolder!.name}"?',
      isMove: true,
    );

    if (confirmed == true && context.mounted) {
      final results = await provider.moveSelectedImages();

      // Only show dialog if there were failures
      final failCount = results.where((r) => !r.success).length;
      if (failCount > 0 && context.mounted) {
        _showResultDialog(context, results, 'Moved');
      }
    }
  }

  Future<void> _handleCopy(
    BuildContext context,
    ImagePickerProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Copy Files',
      'Copy ${provider.selectionCount} file(s) to "${provider.selectedTargetFolder!.name}"?',
      isMove: false,
    );

    if (confirmed == true && context.mounted) {
      final results = await provider.copySelectedImages();

      // Only show dialog if there were failures
      final failCount = results.where((r) => !r.success).length;
      if (failCount > 0 && context.mounted) {
        _showResultDialog(context, results, 'Copied');
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    required bool isMove,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isMove ? Colors.deepPurple : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isMove ? 'Move' : 'Copy'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, List results, String action) {
    final successCount = results.where((r) => r.success).length;
    final failCount = results.length - successCount;

    // Collect error messages
    final errors = results
        .where((r) => !r.success)
        .map((r) => r.errorMessage ?? 'Unknown error')
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Errors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$action $successCount file(s) successfully.'),
              const SizedBox(height: 12),
              Text(
                'Failed: $failCount',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Error details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...errors
                  .take(3)
                  .map(
                    (error) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        '• $error',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              if (errors.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '... and ${errors.length - 3} more',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
