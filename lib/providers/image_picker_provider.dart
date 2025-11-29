import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/image_file_info.dart';
import '../models/folder_info.dart';
import '../models/operation_result.dart';
import '../services/file_scanner_service.dart';
import '../services/file_operation_service.dart';
import '../services/folder_service.dart';

/// Main state provider for the application
/// Professional state management with grid size control!
class ImagePickerProvider with ChangeNotifier {
  // Source folder state
  String? _sourceFolderPath;
  List<ImageFileInfo> _images = [];
  bool _isScanning = false;
  int _totalImagesFound = 0;
  StreamSubscription<ImageFileInfo>? _scanSubscription;

  // Target folders state
  String _targetRootPath = 'E:\\picture'; // Default, can be changed
  List<FolderInfo> _targetFolders = [];
  FolderInfo? _selectedTargetFolder;

  // Selected images
  final Set<ImageFileInfo> _selectedImages = {};

  // Operation state
  bool _isOperating = false;
  int _operationProgress = 0;
  int _operationTotal = 0;

  // Grid display state
  int _gridColumnCount = 2; // Default 2 columns

  // Getters - read-only access
  String? get sourceFolderPath => _sourceFolderPath;
  List<ImageFileInfo> get images => _images;
  bool get isScanning => _isScanning;
  int get totalImagesFound => _totalImagesFound;

  String get targetRootPath => _targetRootPath;
  List<FolderInfo> get targetFolders => _targetFolders;
  FolderInfo? get selectedTargetFolder => _selectedTargetFolder;

  Set<ImageFileInfo> get selectedImages => _selectedImages;
  bool get hasSelection => _selectedImages.isNotEmpty;
  int get selectionCount => _selectedImages.length;

  bool get isOperating => _isOperating;
  int get operationProgress => _operationProgress;
  int get operationTotal => _operationTotal;
  double get operationProgressPercent =>
      _operationTotal > 0 ? _operationProgress / _operationTotal : 0.0;

  int get gridColumnCount => _gridColumnCount;

  ImagePickerProvider() {
    // Load target folders on init
    loadTargetFolders();
  }

  /// Set source folder and start scanning
  Future<void> setSourceFolder(String folderPath) async {
    // Cancel any ongoing scan
    await _scanSubscription?.cancel();

    _sourceFolderPath = folderPath;
    _images.clear();
    _selectedImages.clear();
    _totalImagesFound = 0;
    _isScanning = true;
    notifyListeners();

    // Start streaming scan
    final stream = FileScannerService.scanDirectory(folderPath);
    _scanSubscription = stream.listen(
      (imageInfo) {
        // Add image and sort by size
        _images.add(imageInfo);
        _images.sort(); // Uses compareTo implementation
        _totalImagesFound = _images.length;

        // Notify every 10 images to avoid excessive updates
        if (_totalImagesFound % 10 == 0 || _totalImagesFound < 10) {
          notifyListeners();
        }
      },
      onDone: () {
        _isScanning = false;
        notifyListeners();
      },
      onError: (error) {
        _isScanning = false;
        notifyListeners();
        debugPrint('Scan error: $error');
      },
    );
  }

  /// Load target folders from specified path (recursive)
  void loadTargetFolders() {
    _targetFolders = FolderService.getSubfoldersRecursive(_targetRootPath);
    notifyListeners();
  }

  /// Set target root path and reload folders
  Future<void> setTargetRootPath(String? path) async {
    if (path != null && path.isNotEmpty) {
      _targetRootPath = path;
      _selectedTargetFolder = null; // Clear selection
      loadTargetFolders();
    }
  }

  /// Select target folder
  void selectTargetFolder(FolderInfo folder) {
    _selectedTargetFolder = folder;
    notifyListeners();
  }

  /// Toggle image selection
  void toggleImageSelection(ImageFileInfo image) {
    if (_selectedImages.contains(image)) {
      _selectedImages.remove(image);
    } else {
      _selectedImages.add(image);
    }
    notifyListeners();
  }

  /// Select all images
  void selectAll() {
    _selectedImages.clear();
    _selectedImages.addAll(_images);
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedImages.clear();
    notifyListeners();
  }

  /// Set grid column count (1-4 columns)
  void setGridColumnCount(int count) {
    _gridColumnCount = count.clamp(1, 4);
    notifyListeners();
  }

  /// Move selected images to target folder
  Future<List<OperationResult>> moveSelectedImages() async {
    if (_selectedTargetFolder == null || _selectedImages.isEmpty) {
      return [];
    }

    _isOperating = true;
    _operationProgress = 0;
    _operationTotal = _selectedImages.length;
    notifyListeners();

    final results = <OperationResult>[];
    final imagesToMove = _selectedImages.toList();

    for (final image in imagesToMove) {
      final result = await FileOperationService.moveFile(
        image,
        _selectedTargetFolder!.path,
      );
      results.add(result);

      // Update progress
      _operationProgress++;

      // Remove from list if successful
      if (result.success) {
        _images.remove(image);
        _selectedImages.remove(image);
        _totalImagesFound = _images.length;
      }

      notifyListeners();
    }

    _isOperating = false;
    notifyListeners();

    return results;
  }

  /// Copy selected images to target folder
  Future<List<OperationResult>> copySelectedImages() async {
    if (_selectedTargetFolder == null || _selectedImages.isEmpty) {
      return [];
    }

    _isOperating = true;
    _operationProgress = 0;
    _operationTotal = _selectedImages.length;
    notifyListeners();

    final results = <OperationResult>[];
    final imagesToCopy = _selectedImages.toList();

    for (final image in imagesToCopy) {
      final result = await FileOperationService.copyFile(
        image,
        _selectedTargetFolder!.path,
      );
      results.add(result);

      // Update progress
      _operationProgress++;
      notifyListeners();
    }

    _isOperating = false;
    _selectedImages.clear();
    notifyListeners();

    return results;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
