import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/secure_credentials_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../models/auth_models.dart';

/// Servicio para autenticación
class AuthService {
  final HttpService _http;
  final StorageService _storage;
  final SecureCredentialsService _secureStorage;

  AuthService(this._http, this._storage, this._secureStorage) {
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
  bool _isRefreshing = false;

  /// Intenta refrescar el token
  Future<bool> refreshTokenIfNeeded() async {
    // Evitar múltiples refreshes simultáneos
    if (_isRefreshing) {
      return true;
    }

    try {
      _isRefreshing = true;
      // Verificar si hay sesión activa
      final hasSession = await _storage.hasActiveSession();
      if (!hasSession) return false;

      // Verificar si tenemos token y su expiración en storage
      final tokenData = await _storage.getTokenData();
      if (tokenData == null) return false;

      final expiresAt = tokenData.expiresAt;
      final now = DateTime.now();

      // Si falta suficiente tiempo, no refrescar
      if (expiresAt.difference(now) > ApiConfig.refreshTokenBeforeExpiry) {
        return true;
      }

      // Intentar primero login silencioso con credenciales guardadas
      final saved = await _secureStorage.getCredentials();
      final username = saved['username'];
      final password = saved['password'];
      
      if (username != null && password != null) {
        final loginRequest = LoginRequest(username: username, password: password);
        final loginResponse = await login(loginRequest);
        if (loginResponse.isSuccessful) {
          return true;
        }
      }

      // Si el login silencioso falla, intentar refresh token
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
        
        // Actualizar también los datos de login si están disponibles
        if (response.content != null) {
          await _storage.setLoginData(response.content!.toJson());
        }
        
        return true;
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
