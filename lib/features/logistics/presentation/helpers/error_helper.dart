import 'package:flutter/material.dart';
import '../../../../core/models/api_response.dart';

/// Helper para manejo de mensajes en UI (éxito y errores)
class MessageHelper {
  /// Muestra un mensaje basado en ApiResponse (éxito o error)
  static void showFromResponse(BuildContext context, ApiResponse response) {
    if (response.isSuccessful) {
      showSuccessSnackBar(context, response.message);
    } else {
      showErrorSnackBar(context, response.messageDetail);
    }
  }

  /// Muestra un mensaje de éxito en SnackBar
  static void showSuccessSnackBar(BuildContext context, String? message) {
    if (message?.isEmpty ?? true) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un diálogo de error
  static Future<void> showError(BuildContext context, dynamic error) async {
    String message = '';
    String detail = '';

    if (error is Map<String, dynamic>) {
      detail = error['messageDetail'] ?? '';
      message = detail.isEmpty ? (error['message'] ?? '') : '';
    } else {
      message = error.toString();
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un error en un SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    String message = '';

    if (error is String) {
      message = error;
    } else if (error is Map<String, dynamic>) {
      message = error['messageDetail'] ?? '';
      if (message.isEmpty) {
        message = error['message'] ?? '';
      }
    } else {
      message = error.toString();
    }

    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un mensaje de advertencia en SnackBar
  static void showWarning(BuildContext context, String message) {
    if (message.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un SnackBar con ícono y estilo elaborado
  static void showIconSnackBar(BuildContext context, {
    required String message,
    required bool isSuccess,
    Duration? successDuration,
    Duration? errorDuration,
  }) {
    if (message.isEmpty) return;

    final duration = isSuccess 
        ? (successDuration ?? const Duration(seconds: 4))
        : (errorDuration ?? const Duration(seconds: 5));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isSuccess 
            ? const Color(0xFF4CAF50) 
            : const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un mensaje de información en SnackBar
  static void showInfo(BuildContext context, String message) {
    if (message.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.info,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un diálogo de error bloqueante que impide operaciones hasta que el usuario lo acepte
  static Future<void> showBlockingErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => PopScope(
        canPop: false, // Evita que se cierre con el botón Atrás
        child: AlertDialog(
          backgroundColor: const Color(0xFFFFEBEE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFE53E3E),
              width: 2,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFD32F2F),
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5D4037),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de advertencia bloqueante (amarillo) para mensajes de usuario
  static Future<void> showBlockingWarningDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => PopScope(
        canPop: false, // Evita que se cierre con el botón Atrás
        child: AlertDialog(
          backgroundColor: const Color(0xFFFFF3CD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFFF9800),
              width: 2,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE65100),
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Advertencia',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5D4037),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un widget de error con opción de reintento
  static Widget buildErrorWidget({
    required String error,
    VoidCallback? onRetry,
  }) {
    // Si el error es de sesión expirada, muestra un mensaje especial
    final isSessionExpired = error.toLowerCase().contains('sesión') || 
                            error.toLowerCase().contains('session');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSessionExpired ? Icons.login_outlined : Icons.error_outline,
              size: 48,
              color: isSessionExpired ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isSessionExpired ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            if (isSessionExpired)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar Sesión'),
              )
            else if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
          ],
        ),
      )),
    );
  }
}

/// Alias para mantener compatibilidad con el código existente
typedef ErrorHelper = MessageHelper;

/// Extension para ApiResponse que facilita mostrar mensajes
extension ApiResponseMessageExt<T> on ApiResponse<T> {
  /// Muestra el mensaje apropiado según el tipo de respuesta
  void showMessage(BuildContext context) {
    MessageHelper.showFromResponse(context, this);
  }
  
  /// Muestra el mensaje solo si es de éxito
  void showSuccessMessage(BuildContext context) {
    if (isSuccessful) {
      MessageHelper.showSuccessSnackBar(context, message);
    }
  }
  
  /// Muestra el mensaje solo si es de error
  void showErrorMessage(BuildContext context) {
    if (!isSuccessful) {
      MessageHelper.showErrorSnackBar(context, messageDetail);
    }
  }
}
