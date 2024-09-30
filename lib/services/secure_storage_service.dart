import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final String _tokenKey = 'access_token';
  final String _idkey = 'id';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveID(String id) async {
    await _storage.write(key: _idkey, value: id);
  }

  Future<String?> getID() async {
    return await _storage.read(key: _idkey);
  }

  Future<void> deleteID() async {
    await _storage.delete(key: _idkey);
  }
}
