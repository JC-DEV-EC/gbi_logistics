import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenamiento persistente
class StorageService {
  final _prefs = SharedPreferences.getInstance();
  // Claves para datos de sesión
  static const _tokenKey = 'auth_token';
  static const _tokenExpiryKey = 'auth_token_expiry';
  static const _loginDataKey = 'auth_login_data';
  static const _sessionKey = 'session_active';

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

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final prefs = await _prefs;
    return prefs.getBool(_sessionKey) ?? false;
  }

  /// Guarda los datos de login
  Future<void> setLoginData(Map<String, dynamic> loginData) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_loginDataKey, jsonEncode(loginData)),
      prefs.setBool(_sessionKey, true),
    ]);
  }

  /// Obtiene los datos de login almacenados
  Future<Map<String, dynamic>?> getLoginData() async {
    final prefs = await _prefs;
    final data = prefs.getString(_loginDataKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Limpia todos los datos de la sesión
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_loginDataKey),
      prefs.remove(_sessionKey),
    ]);
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
