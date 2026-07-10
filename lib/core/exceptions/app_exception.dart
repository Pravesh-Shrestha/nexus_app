class AppException implements Exception {
  final String title;
  final String message;
  final String? actionText;
  final Function()? onAction;

  AppException({
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  String toString() {
    return 'AppException(title: $title, message: $message, actionText: $actionText)';
  }
}
