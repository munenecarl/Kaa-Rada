import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feed_page.dart'; // Import your FeedPage

class DietaryGoalsPage extends StatefulWidget {
  @override
  _DietaryGoalsPageState createState() => _DietaryGoalsPageState();
}

class _DietaryGoalsPageState extends State<DietaryGoalsPage> {
  final _formKey = GlobalKey<FormState>();
  String _goal = '';

  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Your Goal'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Your Goal (e.g., lose weight, gain muscle)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your goal';
                  }
                  return null;
                },
                onSaved: (value) => _goal = value!,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Get the current user's ID
        final userId = _supabase.auth.currentUser!.id;

        // Update the secondary_users table
        await _supabase
            .from('secondary_users')
            .update({'dietary_goals': _goal}).eq('id', userId);

        // If we reach here, it means the update was successful
        // Navigate to feed page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FeedPage()),
        );
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save goal: $e')),
        );
      }
    }
  }
}
