import 'package:logger/logger.dart';

/// Default logger instance for bifrost.
///
/// Override this to customize logging behavior:
/// ```dart
/// bifrostLogger = Logger(
///   printer: PrettyPrinter(methodCount: 0),
///   level: Level.debug,
/// );
/// ```
Logger bifrostLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
