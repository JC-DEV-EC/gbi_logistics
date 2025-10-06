import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'version_service.dart';
import '../services/app_logger.dart';

/// Servicio para manejar actualizaciones de la aplicación
class AppUpdateService {
  static AppUpdateService? _instance;
  static AppUpdateService get instance => _instance ??= AppUpdateService._();
  
  AppUpdateService._();
  
  bool _isShowingUpdateDialog = false;
  
  /// Maneja las respuestas de versión del backend
  void handleVersionResponse(BuildContext? context, VersionResponse versionResponse) {
    if (context == null || !context.mounted) {
      AppLogger.log('Context not available for version check', source: 'AppUpdateService');
      return;
    }
    
    if (versionResponse.updateRequired) {
      _showForceUpdateDialog(context, versionResponse);
    } else if (versionResponse.updateAvailable) {
      _showOptionalUpdateDialog(context, versionResponse);
    }
  }
  
  /// Muestra dialog de actualización obligatoria
  void _showForceUpdateDialog(BuildContext context, VersionResponse versionResponse) {
    if (_isShowingUpdateDialog) return;
    _isShowingUpdateDialog = true;

    // Navigator.of(context).popUntil((route) => route.isFirst); // Opcional: Volver a la primera ruta
    
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // Usar el navigator raíz para asegurar que el diálogo esté sobre todo
      builder: (context) => PopScope(
        canPop: false, // Prevenir cierre con botón atrás
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.orange),
              SizedBox(width: 8),
              Text('Actualización Requerida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                versionResponse.updateMessage ?? 
                'Se requiere actualizar la aplicación para continuar.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (versionResponse.minVersion != null)
                Text(
                  'Versión mínima requerida: ${versionResponse.minVersion}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Versión actual: ${VersionService.instance.version}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                _openAppStore(versionResponse.updateUrl);
                // Opcionalmente, cerrar la aplicación después de abrir la tienda
                // SystemNavigator.pop(); // Descomentar si quieres forzar el cierre de la app
              },
              icon: const Icon(Icons.download),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isShowingUpdateDialog = false;
    });
  }
  
  /// Muestra dialog de actualización opcional
  void _showOptionalUpdateDialog(BuildContext context, VersionResponse versionResponse) {
    if (_isShowingUpdateDialog) return;
    _isShowingUpdateDialog = true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.update, color: Colors.green),
            SizedBox(width: 8),
            Text('Actualización Disponible'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              versionResponse.updateMessage ?? 
              'Hay una nueva versión disponible de la aplicación.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (versionResponse.latestVersion != null)
              Text(
                'Nueva versión: ${versionResponse.latestVersion}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Versión actual: ${VersionService.instance.version}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isShowingUpdateDialog = false;
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _isShowingUpdateDialog = false;
              _openAppStore(versionResponse.updateUrl);
            },
            icon: const Icon(Icons.download),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).then((_) {
      _isShowingUpdateDialog = false;
    });
  }
  
  /// Abre la tienda de aplicaciones
  void _openAppStore(String? updateUrl) async {
    String url = updateUrl ?? _getDefaultStoreUrl();
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.error('Cannot launch update URL: $url', source: 'AppUpdateService');
      }
    } catch (e) {
      AppLogger.error('Error opening app store', error: e, source: 'AppUpdateService');
    }
  }
  
  /// Obtiene la URL por defecto de la tienda según la plataforma
  String _getDefaultStoreUrl() {
    final platform = VersionService.instance.platform;
    
    switch (platform) {
      case 'android':
        return 'https://play.google.com/store/apps/details?id=${VersionService.instance.debugInfo['packageName']}';
      case 'ios':
        return 'https://apps.apple.com/app/gbi-logistics/id1234567890'; // Reemplazar con el ID real
      default:
        return 'https://gbilogistics.com/download'; // URL de descarga genérica
    }
  }

  /// Verifica si la versión actual requiere actualización
  /// Retorna true si se requiere actualización, false si no
  Future<bool> checkVersionBeforeLogin(BuildContext context, VersionResponse versionResponse) async {
    if (versionResponse.updateRequired) {
      _showForceUpdateDialog(context, versionResponse);
      return true;
    }
    return false;
  }
}