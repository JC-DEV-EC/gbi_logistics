import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Servicio para manejar versiones y actualizaciones de la aplicación
class VersionService {
  static VersionService? _instance;
  static VersionService get instance => _instance ??= VersionService._();
  
  VersionService._();
  
  PackageInfo? _packageInfo;
  
  /// Inicializa el servicio de versión
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      debugPrint('VersionService initialized: $fullVersion');
      debugPrint('Version for display: $version');
      debugPrint('Build number: $buildNumber');
    } catch (e) {
      debugPrint('Error initializing VersionService: $e');
      // Asegurar valores por defecto en caso de error
      _packageInfo = PackageInfo(
        version: '1.0.0',
        buildNumber: '5',
        appName: 'GBI Logistics',
        packageName: 'com.gbi.logistics',
      );
    }
  }
  
  /// Obtiene la versión completa del app (ej: "1.0.0+1")
  String get fullVersion {
    if (_packageInfo == null) return '1.0.0+5';
    return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
  }
  
  /// Obtiene solo la versión (ej: "1.0.0.0")
  String get version {
    if (_packageInfo == null) return '1.0.0.5';
    // Asegurarnos de que el formato sea correcto para el backend
    return '${_packageInfo!.version}.${_packageInfo!.buildNumber}';
  }
  
  /// Obtiene la versión original de 3 números para headers HTTP
  String get originalVersion {
    if (_packageInfo == null) return '1.0.0';
    return _packageInfo!.version;
  }
  
  /// Obtiene solo el build number (ej: "1")
  String get buildNumber {
    if (_packageInfo == null) return '1';
    return _packageInfo!.buildNumber;
  }
  
  /// Obtiene información de la plataforma
  String get platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  /// Headers que se envían automáticamente en cada petición HTTP
  Map<String, String> get versionHeaders => {
    'X-App-Version': version,  // Cambio: usar version en lugar de originalVersion
    'X-App-Build': buildNumber,
    'X-App-Platform': platform,
    'X-Client-Type': 'mobile-app',
  };
  
  /// Información completa para logging o debug
  Map<String, dynamic> get debugInfo => {
    'version': version,
    'buildNumber': buildNumber,
    'fullVersion': fullVersion,
    'platform': platform,
  };
}

/// Modelo para respuestas de versión del backend
class VersionResponse {
  final bool updateRequired;
  final bool updateAvailable;
  final String? minVersion;
  final String? latestVersion;
  final String? updateMessage;
  final String? updateUrl;
  
  VersionResponse({
    required this.updateRequired,
    this.updateAvailable = false,
    this.minVersion,
    this.latestVersion,
    this.updateMessage,
    this.updateUrl,
  });
  
  factory VersionResponse.fromHeaders(Map<String, String> headers) {
    return VersionResponse(
      updateRequired: headers['X-Update-Required']?.toLowerCase() == 'true',
      updateAvailable: headers['X-Update-Available']?.toLowerCase() == 'true',
      minVersion: headers['X-Min-Version'],
      latestVersion: headers['X-Latest-Version'],
      updateMessage: headers['X-Update-Message'],
      updateUrl: headers['X-Update-URL'],
    );
  }
  
  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      updateRequired: json['update_required'] ?? false,
      updateAvailable: json['update_available'] ?? false,
      minVersion: json['min_version'],
      latestVersion: json['latest_version'],
      updateMessage: json['update_message'],
      updateUrl: json['update_url'],
    );
  }
}