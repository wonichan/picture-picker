/// Result of file operation (move/copy)
class OperationResult {
  final bool success;
  final String? errorMessage;
  final String? sourcePath;
  final String? targetPath;

  OperationResult({
    required this.success,
    this.errorMessage,
    this.sourcePath,
    this.targetPath,
  });

  factory OperationResult.success(String source, String target) {
    return OperationResult(
      success: true,
      sourcePath: source,
      targetPath: target,
    );
  }

  factory OperationResult.failure(String source, String error) {
    return OperationResult(
      success: false,
      sourcePath: source,
      errorMessage: error,
    );
  }
}
