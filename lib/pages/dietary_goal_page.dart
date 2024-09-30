import 'package:flutter/material.dart';
import 'package:kaa_rada/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feed_page.dart'; // Make sure this import is correct for your project structure
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DietaryGoalsPage extends StatefulWidget {
  @override
  _DietaryGoalPageState createState() => _DietaryGoalPageState();
}

class _DietaryGoalPageState extends State<DietaryGoalsPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  late String _goal;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Get the current user's ID
        final userId = await SecureStorageService().getID();
        if (userId == null) {
          throw Exception('User ID not found in secure storage');
        }
        print('Attempting to calculate weekly goals for user: $userId');
        print('Goal: $_goal');

        // Call the edge function to calculate weekly goals
        final response = await _supabase.functions.invoke(
          'weekly_goal_calculator',
          body: {
            'userId': userId,
            'dietaryGoal': _goal,
          },
        );

        print('Raw response: ${response.data}');

        if (response.status != 200) {
          throw Exception('Failed to calculate weekly goals: ${response.data}');
        }

        // The response.data is already a Map, no need to parse it
        final jsonResponse = response.data as Map<String, dynamic>;

        print('Parsed response: $jsonResponse');

        // Access the data
        final userData = jsonResponse['data'] as Map<String, dynamic>;
        final weeklyCalories = userData['weekly_calories'];
        final weeklyProtein = userData['weekly_protein'];
        final weeklyCarbs = userData['weekly_carbs'];
        final weeklyFat = userData['weekly_fat'];

        // Store the data using SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('weekly_calories', weeklyCalories);
        await prefs.setInt('weekly_protein', weeklyProtein);
        await prefs.setInt('weekly_carbs', weeklyCarbs);
        await prefs.setInt('weekly_fat', weeklyFat);
        await prefs.setString('dietary_goal', _goal);

        print('Weekly goals stored in SharedPreferences');

        // If we reach here, it means the calculation was successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Weekly goals calculated and stored successfully!')),
        );

        // Navigate to feed page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FeedPage()),
        );
      } catch (e, stackTrace) {
        print('Error calculating weekly goals: $e');
        print('Stack trace: $stackTrace');
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate weekly goals: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Your Dietary Goal'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Your Dietary Goal'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your dietary goal';
                  }
                  return null;
                },
                onSaved: (value) {
                  _goal = value!;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
