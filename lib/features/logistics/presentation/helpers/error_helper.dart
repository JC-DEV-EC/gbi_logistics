import 'package:flutter/material.dart';

/// Helper para manejo de errores en UI
class ErrorHelper {
  /// Muestra un diálogo de error
  static Future<void> showError(BuildContext context, dynamic error) async {
    String message = 'Error desconocido';
    String detail = '';

    if (error is Map<String, dynamic>) {
      message = error['message'] ?? message;
      detail = error['messageDetail'] ?? '';
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
    String message = 'Error desconocido';

    if (error is Map<String, dynamic>) {
      message = error['message'] ?? message;
    } else {
      message = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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
      ),
    );
  }
}
