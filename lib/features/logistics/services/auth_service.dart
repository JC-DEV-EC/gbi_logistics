import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../models/auth_models.dart';

/// Servicio para autenticación
class AuthService {
  final HttpService _http;
  final StorageService _storage;

  AuthService(this._http, this._storage) {
    _restoreToken();
  }

  Future<LoginResponse?> restoreSession() async {
    final hasSession = await _storage.hasActiveSession();
    final token = await _storage.getToken();
    final loginData = await _storage.getLoginData();
    
    // Solo restaurar si el usuario no cerró sesión explícitamente
    if (hasSession && token != null) {
      _http.setToken(token);
      
      if (loginData != null) {
        return LoginResponse.fromJson(loginData);
      }
    }
    return null;
  }

  Future<void> _restoreToken() async {
    final token = await _storage.getToken();
    if (token != null) {
      _http.setToken(token);
    }
  }

  /// Realiza el login
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _http.post<LoginResponse>(
        ApiEndpoints.login,
        request.toJson(),
        (json) => LoginResponse.fromJson(json),
      );

      if (response.isSuccessful && response.content?.token != null) {
        final token = response.content!.token!;
        final loginData = response.content!;
        // Guardar token y datos de login
        _http.setToken(token);
        await _storage.setToken(token);
        await _storage.setLoginData(loginData.toJson());
      } else if (!response.isSuccessful) {
        return ApiResponse.error(
          messageDetail: response.messageDetail,  // Solo el mensaje del backend
          content: LoginResponse.empty(),
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error(
        messageDetail: null,  // Dejar que el backend proporcione el mensaje
        content: LoginResponse.empty(),
      );
    }
  }

  Future<void> logout() async {
    _http.setToken(null);
    await _storage.clearSession();
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    // Validar el token haciendo una petición al dashboard
    final response = await _http.get<dynamic>(
      ApiEndpoints.dashboardData,
      (json) => json['content'],
      queryParams: {'version': ApiConfig.version},
      suppressAuthHandling: true,
    );

    return response.isSuccessful;
  }
  /// Intenta refrescar el token
  Future<bool> refreshTokenIfNeeded() async {
    // Verificar si tenemos token y su expiración en storage
    final tokenData = await _storage.getTokenData(); // Debe devolver { token, expiresAt }
    if (tokenData == null) return false;

    final expiresAt = tokenData.expiresAt;
    final now = DateTime.now();

    // Si falta suficiente tiempo, no refrescar
    if (expiresAt.difference(now) > ApiConfig.refreshTokenBeforeExpiry) {
      return true;
    }

    // Llamar al endpoint de refresh
    final response = await _http.post<LoginResponse>(
      ApiEndpoints.refreshToken,
      {
        'token': tokenData.token,
      },
      (json) => LoginResponse.fromJson(json),
      suppressAuthHandling: true,
    );

    if (response.isSuccessful && response.content?.token != null) {
      final newToken = response.content!.token!;
      _http.setToken(newToken);
      await _storage.setToken(newToken);
      return true;
    }

    return false;
  }
}
