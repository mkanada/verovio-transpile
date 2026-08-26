/// Port of the Verovio logging functions (`vrv.h` LogError/LogWarning/etc.).
library;

import 'dart:io' show stderr, stdout;

/// Log levels, mirroring the verbosity handling in `vrv.cpp`.
enum LogLevel {
  off,
  error,
  warning,
  info,
  debug,
}

LogLevel _logLevel = LogLevel.warning;

/// The current global log level (defaults to [LogLevel.warning], like the C++).
LogLevel get logLevel => _logLevel;

set logLevel(LogLevel level) => _logLevel = level;

void logError(String message) {
  if (_logLevel.index >= LogLevel.error.index) {
    stderr.writeln('Error: $message');
  }
}

void logWarning(String message) {
  if (_logLevel.index >= LogLevel.warning.index) {
    stdout.writeln('Warning: $message');
  }
}

void logInfo(String message) {
  if (_logLevel.index >= LogLevel.info.index) stdout.writeln(message);
}

void logDebug(String message) {
  if (_logLevel.index >= LogLevel.debug.index) {
    stdout.writeln('Debug: $message');
  }
}
