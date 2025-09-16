import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenamiento persistente
class StorageService {
  final _prefs = SharedPreferences.getInstance();
  static const _tokenKey = 'auth_token';
  static const _tokenExpiryKey = 'auth_token_expiry';

  /// Obtiene el token almacenado
  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  /// Guarda el token
  Future<void> setToken(String token) async {
    // Asumimos que el token JWT tiene una duración de 1 hora
    final expiresAt = DateTime.now().add(const Duration(hours: 1));
    await setTokenWithExpiry(token, expiresAt);
  }

  /// Guarda el token con fecha de expiración
  Future<void> setTokenWithExpiry(String token, DateTime expiresAt) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());
  }

  /// Elimina el token
  Future<void> removeToken() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  /// Obtiene los datos del token incluyendo expiración
  Future<TokenData?> getTokenData() async {
    final prefs = await _prefs;
    final token = await getToken();
    final expiryStr = prefs.getString(_tokenExpiryKey);
    
    if (token == null || expiryStr == null) return null;
    
    return TokenData(
      token: token,
      expiresAt: DateTime.parse(expiryStr),
    );
  }

  /// Verifica si hay un token almacenado
  Future<bool> hasToken() async {
    final prefs = await _prefs;
    return prefs.containsKey(_tokenKey);
  }
}

/// Datos del token incluyendo expiración
class TokenData {
  final String token;
  final DateTime expiresAt;

  const TokenData({
    required this.token,
    required this.expiresAt,
  });
}
