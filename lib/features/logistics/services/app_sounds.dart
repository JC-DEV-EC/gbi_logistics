import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Helper para reproducir sonidos de feedback
class AppSounds {
  // Mantener una única instancia del player para evitar problemas en Android
  static AudioPlayer? _player;
  
  // Cache para los sources de audio
  static final Map<String, Source> _sources = {};
  
  // Flag para inicialización
  static bool _initialized = false;

  /// Inicializa el reproductor y precarga los sonidos
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    try {
      // Crear una nueva instancia del player si no existe
      _player?.dispose();
      _player = AudioPlayer(playerId: 'gbi_sounds');
      
      // Configurar el player
      await _player?.setReleaseMode(ReleaseMode.release);
      await _player?.setVolume(1.0);
      
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
      final player = _player;
      if (source != null && player != null) {
        await player.stop(); // Detener cualquier sonido previo
        await player.play(source);
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
      final player = _player;
      if (source != null && player != null) {
        await player.stop(); // Detener cualquier sonido previo
        await player.play(source);
      }
    } catch (e) {
      debugPrint('Error reproduciendo sonido de éxito: $e');
    }
  }

  /// Libera los recursos del reproductor
  static Future<void> dispose() async {
    try {
      await _player?.dispose();
      _player = null;
      _initialized = false;
      _sources.clear();
    } catch (e) {
      debugPrint('Error liberando recursos de audio: $e');
    }
  }
}
