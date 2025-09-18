import 'package:audioplayers/audioplayers.dart';

class AppSounds {
  static final AudioPlayer _player = AudioPlayer(playerId: 'gbi_sounds');
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _player.setReleaseMode(ReleaseMode.stop);
      _initialized = true;
    }
  }

  static Future<void> error() async {
    try {
      await _ensureInitialized();
      await _player.play(AssetSource('assets/sounds/error.wav'), volume: 5.0);
    } catch (_) {}
  }

  static Future<void> success() async {
    try {
      await _ensureInitialized();
      await _player.play(AssetSource('assets/sounds/success.wav'), volume: 5.0);
    } catch (_) {}
  }
}