// lib/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../widget/auth_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Navigate to home page or show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign up successful')),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        child: AuthForm(
          onSubmit: (email, password) {
            BlocProvider.of<AuthBloc>(context).add(
              SignUpSubmitted(email: email, password: password),
            );
          },
          buttonText: 'Sign Up',
        ),
      ),
    );
  }
}
