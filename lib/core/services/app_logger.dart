import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
    String type = 'INFO'
  }) {
    final logMessage = '''
----------------------------------------
[$type] ${source != null ? '[$source]' : ''}: $message
${error != null ? '\nError: $error' : ''}
${stackTrace != null ? '\nStack: \n$stackTrace' : ''}
----------------------------------------''';

    // Siempre usar print en lugar de developer.log para ver en la consola
    print(logMessage);
  }

  static void button(String buttonName, {String? screen}) {
    log('Button pressed: $buttonName', source: screen ?? 'UI');
  }

  static void textInput(String fieldName, String value, {String? screen}) {
    log('Text input [$fieldName]: $value', source: screen ?? 'UI');
  }

  static void navigation(String from, String to) {
    log('Navigation: $from -> $to', source: 'Navigation');
  }

  static void apiCall(String endpoint, {String? method, String? body}) {
    log(
      'API Call: ${method ?? 'GET'} $endpoint${body != null ? '\nBody: $body' : ''}',
      source: 'API',
    );
  }

  static void apiResponse(String endpoint, {int? statusCode, String? body}) {
    log(
      'API Response: $endpoint\nStatus: ${statusCode ?? 'Unknown'}\nBody: ${body ?? 'No body'}',
      source: 'API',
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? source}) {
    log(
      message,
      error: error,
      stackTrace: stackTrace,
      source: source,
      type: 'ERROR',
    );
  }

  static void state(String message, {String? source}) {
    log(message, source: source ?? 'State', type: 'STATE');
  }
}