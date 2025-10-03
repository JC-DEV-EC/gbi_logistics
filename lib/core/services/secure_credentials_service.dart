import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsService {
  static const _storage = FlutterSecureStorage();
  
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';
  
  // Almacenar credenciales
  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }
  
  // Obtener credenciales guardadas
  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);
    
    return {
      'username': username,
      'password': password,
    };
  }
  
  // Verificar si hay credenciales guardadas
  Future<bool> hasCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);
    return username != null && password != null;
  }
  
  // Limpiar credenciales (útil para logout)
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
  }
  
  // Actualizar solo la contraseña
  Future<void> updatePassword(String newPassword) async {
    await _storage.write(key: _keyPassword, value: newPassword);
  }
}