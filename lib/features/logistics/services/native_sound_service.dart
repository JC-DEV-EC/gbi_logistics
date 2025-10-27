import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Servicio para reproducir sonidos nativos del sistema
class NativeSoundService {
  static const MethodChannel _channel = MethodChannel('com.gbilogistics/sounds');

  /// Reproduce sonido de error/notificación del sistema
  static void playErrorSound() {
    try {
      _channel.invokeMethod('playErrorSound');
    } catch (e) {
      debugPrint('Error reproduciendo sonido nativo: $e');
    }
  }
}
