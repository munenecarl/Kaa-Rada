import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';

class SupabaseAuthService {
  final SupabaseClient _client;
  final SecureStorageService _secureStorage = SecureStorageService();

  SupabaseAuthService(this._client);

  Future<void> logIn({required String email, required String password}) async {
    try {
      print("Attempting to log in...");
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
        if (response.user != null) {
          await _secureStorage.saveID(response.user!.id);
        }
        print("Login successful. Token: ${response.session!.accessToken}");
        print("User ID: ${response.user?.id}");
      } else {
        print("Login failed: No session returned");
      }
    } catch (e) {
      print("Login error: $e");
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      print("Attempting to sign up...");
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
        if (response.user != null) {
          await _secureStorage.saveID(response.user!.id);
        }
        print("Signup successful. Token: ${response.session!.accessToken}");
        print("User ID: ${response.user?.id}");
      } else {
        print("Signup failed: No session returned");
      }
    } catch (e) {
      print("Signup error: $e");
    }
  }

  // Future<String?> logIn({required String email, required String password}) async {
  //   try {
  //     print("Attempting to log in...");
  //     final response = await _client.auth.signInWithPassword(
  //       email: email,
  //       password: password,
  //     );
  //     if (response.session != null) {
  //       await _secureStorage.saveToken(response.session!.accessToken);
  //       print("Login successful. Token: ${response.session!.accessToken}");
  //       return response.user?.id;  // Return the user ID
  //     } else {
  //       print("Login failed: No session returned");
  //     }
  //   } catch (e) {
  //     print("Login error: $e");
  //   }
  //   return null;
  // }

  // Future<String?> signUp({required String email, required String password}) async {
  //   try {
  //     print("Attempting to sign up...");
  //     final response = await _client.auth.signUp(
  //       email: email,
  //       password: password,
  //     );
  //     if (response.session != null) {
  //       await _secureStorage.saveToken(response.session!.accessToken);
  //       print("Signup successful. Token: ${response.session!.accessToken}");
  //       return response.user?.id;  // Return the user ID
  //     } else {
  //       print("Signup failed: No session returned");
  //     }
  //   } catch (e) {
  //     print("Signup error: $e");
  //   }
  //   return null;
  // }

  Future<void> logOut() async {
    await _client.auth.signOut();
    await _secureStorage.deleteToken();
    await _secureStorage.deleteID();
    print("Logged out successfully");
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    return token != null;
  }

  // New method to get the current user's ID
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }
}
