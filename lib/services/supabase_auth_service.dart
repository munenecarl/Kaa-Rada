import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

class SupabaseAuthService {
  final SupabaseClient _client;
  final SecureStorageService _secureStorage = SecureStorageService();

  SupabaseAuthService(this._client);

  Future<void> logIn({required String email, required String password}) async {
    try {
      print("Attempting to log in..."); // Add this line
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
        print("Login successful. Token: ${response.session!.accessToken}");
      } else {
        print("Login failed: No session returned");
      }
    } catch (e) {
      print("Login error: $e");
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      print("Attempting to sign up..."); // Add this line
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
        print("Signup successful. Token: ${response.session!.accessToken}");
      } else {
        print("Signup failed: No session returned");
      }
    } catch (e) {
      print("Signup error: $e");
    }
  }

  Future<void> logOut() async {
    await _client.auth.signOut();
    await _secureStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    return token != null;
  }
}
