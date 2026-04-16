class ApiError implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const ApiError({required this.code, required this.message, this.details});

  @override
  String toString() => 'ApiError($code: $message)';
}
