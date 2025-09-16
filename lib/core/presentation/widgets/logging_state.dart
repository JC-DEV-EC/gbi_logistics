import 'package:flutter/material.dart';
import '../../services/app_logger.dart';

abstract class LoggingState<T extends StatefulWidget> extends State<T> {
  String get screenName;

  @override
  void initState() {
    super.initState();
    AppLogger.log('Screen initialized: $screenName', source: 'Navigation');
  }

  @override
  void dispose() {
    AppLogger.log('Screen disposed: $screenName', source: 'Navigation');
    super.dispose();
  }

  void logButton(String buttonName) {
    AppLogger.button(buttonName, screen: screenName);
  }

  void logTextInput(String fieldName, String value) {
    AppLogger.textInput(fieldName, value, screen: screenName);
  }

  void logNavigation(String to) {
    AppLogger.navigation(screenName, to);
  }

  void logState(String message) {
    AppLogger.state(message, source: screenName);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(message, error: error, stackTrace: stackTrace, source: screenName);
  }
}