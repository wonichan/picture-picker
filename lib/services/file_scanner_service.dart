import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import '../models/image_file_info.dart';

/// High-performance file scanner using Isolate for non-blocking operation
/// This is how you write PROFESSIONAL code - not that garbage blocking I/O!
class FileScannerService {
  // Supported image extensions
  static const _imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.tiff',
    '.tif',
    '.heic',
    '.heif',
  ];

  /// Scan directory in background Isolate - NEVER block the UI thread!
  /// Returns a Stream that emits images as they're found
  static Stream<ImageFileInfo> scanDirectory(String directoryPath) {
    // Create a StreamController for progressive results
    final controller = StreamController<ImageFileInfo>();

    // Spawn isolate for background processing
    _spawnScannerIsolate(directoryPath, controller);

    return controller.stream;
  }

  /// Spawn the scanner isolate - this is how Linux kernel does it!
  static Future<void> _spawnScannerIsolate(
    String directoryPath,
    StreamController<ImageFileInfo> controller,
  ) async {
    // Create ReceivePort for communication
    final receivePort = ReceivePort();

    // Spawn isolate with entry point
    await Isolate.spawn(
      _scannerIsolateEntryPoint,
      _IsolateParams(
        directoryPath: directoryPath,
        sendPort: receivePort.sendPort,
      ),
    );

    // Listen to isolate messages
    await for (final message in receivePort) {
      if (message is ImageFileInfo) {
        controller.add(message);
      } else if (message is _ScanComplete) {
        controller.close();
        receivePort.close();
        break;
      } else if (message is _ScanError) {
        controller.addError(message.error);
        controller.close();
        receivePort.close();
        break;
      }
    }
  }

  /// Isolate entry point - runs in separate thread
  static void _scannerIsolateEntryPoint(_IsolateParams params) {
    try {
      final directory = Directory(params.directoryPath);

      if (!directory.existsSync()) {
        params.sendPort.send(_ScanError('Directory does not exist'));
        return;
      }

      // Recursively scan with streaming
      _scanDirectoryRecursive(directory, params.sendPort);

      // Signal completion
      params.sendPort.send(_ScanComplete());
    } catch (e) {
      params.sendPort.send(_ScanError(e.toString()));
    }
  }

  /// Recursive directory scanner - optimized for thousands of files
  static void _scanDirectoryRecursive(Directory dir, SendPort sendPort) {
    try {
      // List directory contents synchronously (we're in isolate, it's OK)
      final entities = dir.listSync();

      for (final entity in entities) {
        if (entity is File) {
          // Check if it's an image file
          if (_isImageFile(entity.path)) {
            try {
              // Create ImageFileInfo and send immediately
              final imageInfo = ImageFileInfo.fromFile(entity);
              sendPort.send(imageInfo);
            } catch (e) {
              // Skip files that can't be read (permissions, etc.)
              continue;
            }
          }
        } else if (entity is Directory) {
          // Recursively scan subdirectories
          _scanDirectoryRecursive(entity, sendPort);
        }
      }
    } catch (e) {
      // Continue on error (e.g., permission denied on some folders)
    }
  }

  /// Check if file is an image based on extension
  static bool _isImageFile(String path) {
    final lowerPath = path.toLowerCase();
    return _imageExtensions.any((ext) => lowerPath.endsWith(ext));
  }

  /// Count total images in directory (fast estimate)
  static Future<int> estimateImageCount(String directoryPath) async {
    int count = 0;
    final completer = Completer<int>();

    final receivePort = ReceivePort();

    await Isolate.spawn(
      _countIsolateEntryPoint,
      _IsolateParams(
        directoryPath: directoryPath,
        sendPort: receivePort.sendPort,
      ),
    );

    await for (final message in receivePort) {
      if (message is int) {
        count = message;
      } else if (message is _ScanComplete) {
        receivePort.close();
        completer.complete(count);
        break;
      }
    }

    return completer.future;
  }

  static void _countIsolateEntryPoint(_IsolateParams params) {
    int count = 0;

    void countDirectory(Directory dir) {
      try {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File && _isImageFile(entity.path)) {
            count++;
          } else if (entity is Directory) {
            countDirectory(entity);
          }
        }
      } catch (e) {
        // Ignore errors
      }
    }

    final directory = Directory(params.directoryPath);
    if (directory.existsSync()) {
      countDirectory(directory);
    }

    params.sendPort.send(count);
    params.sendPort.send(_ScanComplete());
  }
}

/// Parameters for isolate communication
class _IsolateParams {
  final String directoryPath;
  final SendPort sendPort;

  _IsolateParams({required this.directoryPath, required this.sendPort});
}

/// Scan completion marker
class _ScanComplete {
  const _ScanComplete();
}

/// Scan error marker
class _ScanError {
  final String error;
  const _ScanError(this.error);
}
