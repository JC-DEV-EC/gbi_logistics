import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Helper para reproducir sonidos de feedback
class AppSounds {
  // Mantener una única instancia del player para evitar problemas en Android
  static final AudioPlayer _player = AudioPlayer(playerId: 'gbi_sounds');
  
  // Cache para los sources de audio
  static final Map<String, Source> _sources = {};
  
  // Flag para inicialización
  static bool _initialized = false;

  /// Inicializa el reproductor y precarga los sonidos
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    try {
      // Configurar el player
      await _player.setReleaseMode(ReleaseMode.stop);
      
      // Precargar los sonidos
      _sources['error'] = AssetSource('sounds/error.wav');
      _sources['success'] = AssetSource('sounds/success.wav');
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error inicializando sonidos: $e');
    }
  }

  /// Reproduce el sonido de error
  static Future<void> error() async {
    try {
      await _ensureInitialized();
      final source = _sources['error'];
      if (source != null) {
        await _player.stop(); // Detener cualquier sonido previo
        await _player.play(source, volume: 5.0);
      }
    } catch (e) {
      debugPrint('Error reproduciendo sonido de error: $e');
    }
  }

  /// Reproduce el sonido de éxito
  static Future<void> success() async {
    try {
      await _ensureInitialized();
      final source = _sources['success'];
      if (source != null) {
        await _player.stop(); // Detener cualquier sonido previo
        await _player.play(source, volume: 5.0);
      }
    } catch (e) {
      debugPrint('Error reproduciendo sonido de éxito: $e');
    }
  }
}
