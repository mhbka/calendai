/// A generic exception for errors from services.
class ServiceException implements Exception {
  final String message;
  final int statusCode;

  ServiceException(this.message, this.statusCode);

  @override
  String toString() => '$message ($statusCode)';
}