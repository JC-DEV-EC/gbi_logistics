import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Helper para reproducir feedback nativo
class AppSounds {
  /// Reproduce feedback de error
  static Future<void> error() async {
    try {
      // Vibración de error
      await HapticFeedback.heavyImpact();
      // Sonido de error del sistema
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error reproduciendo feedback de error: $e');
    }
  }

  /// Reproduce feedback de éxito
  static Future<void> success() async {
    try {
      // Vibración de éxito
      await HapticFeedback.lightImpact();
      // Sonido de éxito del sistema
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Error reproduciendo feedback de éxito: $e');
    }
  }

  /// No es necesario liberar recursos ya que usamos feedback nativo
  static Future<void> dispose() async {}
}
