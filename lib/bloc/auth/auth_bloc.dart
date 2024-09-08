// lib/bloc/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/supabase_auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseAuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  void _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.logIn(email: event.email, password: event.password);
      emit(AuthSuccess());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  void _onSignUpSubmitted(
      SignUpSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signUp(email: event.email, password: event.password);
      emit(AuthSuccess());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }
}
