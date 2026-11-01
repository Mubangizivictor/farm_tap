import 'package:logger/logger.dart';

abstract class AppLogger {
  void d(String message);
  void i(String message);
  void w(String message, [dynamic error, StackTrace? stackTrace]);
  void e(String message, [dynamic error, StackTrace? stackTrace]);
}

class LoggerImpl implements AppLogger {
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 80,
    ),
  );

  @override
  void d(String message) => _logger.d(message);

  @override
  void i(String message) => _logger.i(message);

  @override
  void w(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  @override
  void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
