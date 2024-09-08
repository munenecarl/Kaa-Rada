// lib/widgets/auth_form.dart
import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final Function(String, String) onSubmit;
  final String buttonText;

  AuthForm({required this.onSubmit, required this.buttonText});

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(_email, _password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              onSaved: (value) => _email = value!,
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              },
              onSaved: (value) => _password = value!,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}