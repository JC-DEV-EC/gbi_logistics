import 'dart:async';

/// Controlador para manejar escaneo de guías con protección contra escaneos múltiples
class ScanController {
  Timer? _debounceTimer;
  bool _isProcessing = false;

  /// Indica si actualmente se está procesando un escaneo
  bool get isProcessing => _isProcessing;

  /// Procesa un escaneo con protección contra múltiples escaneos
  /// 
  /// [onScan] es la función que se ejecutará cuando se acepte el escaneo
  /// [cooldownMs] es el tiempo en milisegundos que debe pasar entre escaneos
  Future<void> processScan(Future<void> Function() onScan, {int cooldownMs = 1000}) async {
    // Si ya estamos procesando o el timer de cooldown está activo, ignorar
    if (_isProcessing || _debounceTimer?.isActive == true) {
      return;
    }

    try {
      _isProcessing = true;
      await onScan();
    } finally {
      _isProcessing = false;
      
      // Iniciar el timer de cooldown
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: cooldownMs), () {
        // Timer expirado, listo para el siguiente escaneo
      });
    }
  }

  /// Libera recursos cuando ya no se necesita el controlador
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}