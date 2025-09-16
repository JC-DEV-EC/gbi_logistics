import 'package:intl/intl.dart';

/// Helper para formateo de fechas
class DateHelper {
  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _timeFormatter = DateFormat('HH:mm');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  /// Formatea una fecha como dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Formatea una hora como HH:mm
  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  /// Formatea una fecha y hora como dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }
}
