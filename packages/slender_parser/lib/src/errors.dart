final class UnexpectedTokenError extends Error {
  final String message;

  UnexpectedTokenError(this.message);

  @override
  String toString() => 'UnexpectedTokenError: $message';
}
