// lib/services/supabase_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabaseClient;

  SupabaseAuthService(this._supabaseClient);

  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    return await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> logIn(
      {required String email, required String password}) async {
    return await _supabaseClient.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<void> logOut() async {
    await _supabaseClient.auth.signOut();
  }
}
