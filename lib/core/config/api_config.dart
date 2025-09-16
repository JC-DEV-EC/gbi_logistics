/// Configuración de la API
class ApiConfig {
  /// Tiempo antes de expiración para refrescar el token (15 minutos)
  static const refreshTokenBeforeExpiry = Duration(minutes: 15);

  /// Intervalo para verificar el estado del token (5 minutos)
  static const tokenCheckInterval = Duration(minutes: 5);
  /// URL base de la API
  static const String baseUrl = 'https://testapi.gbilogistics.net/internaldev';

  /// Versión de la API
  static const String version = '1.0';

  /// Base path para todos los endpoints de la API
  static String get apiPath => '/api/v$version';

  /// Construye una URL completa para un endpoint
  static String buildUrl(String endpoint) {
    return '$apiPath$endpoint';
  }
}

/// Endpoints de la API
class ApiEndpoints {
  static String get auth => ApiConfig.buildUrl('/Auth');
  static String get dashboard => ApiConfig.buildUrl('/Dashboard');
  static String get guide => ApiConfig.buildUrl('/Guide');

  // Auth endpoints
  static String get login => ApiConfig.buildUrl('/Auth/login');
  static String get refreshToken => ApiConfig.buildUrl('/Auth/refresh-token');

  // Dashboard endpoints
  static String get dashboardData => ApiConfig.buildUrl('/Dashboard/dashboard');

  // Guide endpoints
  static String get updateGuideStatus => ApiConfig.buildUrl('/Guide/update-status');
  static String get dispatchToClient => ApiConfig.buildUrl('/Guide/dispatch-to-client');
  static String get newTransportCube => ApiConfig.buildUrl('/Guide/new-transport-cube');
  static String get getTransportCubes => ApiConfig.buildUrl('/Guide/get-transport-cubes');
  static String get getTransportCubeDetails => ApiConfig.buildUrl('/Guide/get-transport-cube-details');
  static String get changeTransportCubeState => ApiConfig.buildUrl('/Guide/change-transport-cube-state');
  static String get changeCubeGuide => ApiConfig.buildUrl('/Guide/change-cube-guide');
  static String get guidesPaginated => ApiConfig.buildUrl('/Guide/guides-paginated');
}
