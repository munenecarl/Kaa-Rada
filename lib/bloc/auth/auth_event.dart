// lib/bloc/auth/auth_event.dart
abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
}

class SignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  SignUpSubmitted({required this.email, required this.password});
}

class CheckAuthStatus extends AuthEvent {}

class LogoutSubmitted extends AuthEvent {}
