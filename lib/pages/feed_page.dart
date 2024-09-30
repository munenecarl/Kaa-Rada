import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  String _classificationResult = '';
  bool _isModelLoading = true;
  final supabase = Supabase.instance.client;
  late SharedPreferences _prefs;
  Map<String, int> _dailyNutrients = {
    'calories': 0,
    'fat': 0,
    'carbs': 0,
    'proteins': 0,
  };
  late DateTime _lastResetDate;

  // Adjust these values to match your model's expected input
  final int inputSize = 224;
  final int channels = 3;
  final int batchSize = 1;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadDailyNutrients();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    } finally {
      setState(() {
        _isModelLoading = false;
      });
    }
  }

  Future<void> _loadDailyNutrients() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if we need to reset
    _lastResetDate = DateTime.parse(_prefs.getString('last_reset_date') ?? DateTime.now().toIso8601String());
    if (_lastResetDate.day != DateTime.now().day) {
      await _resetDailyNutrients();
    } else {
      setState(() {
        _dailyNutrients = {
          'calories': _prefs.getInt('daily_calories') ?? 0,
          'fat': _prefs.getInt('daily_fat') ?? 0,
          'carbs': _prefs.getInt('daily_carbs') ?? 0,
          'proteins': _prefs.getInt('daily_proteins') ?? 0,
        };
      });
    }
  }

  Future<void> _resetDailyNutrients() async {
    await _prefs.remove('daily_calories');
    await _prefs.remove('daily_fat');
    await _prefs.remove('daily_carbs');
    await _prefs.remove('daily_proteins');
    
    setState(() {
      _dailyNutrients = {
        'calories': 0,
        'fat': 0,
        'carbs': 0,
        'proteins': 0,
      };
    });

    // Update last reset date
    _lastResetDate = DateTime.now();
    await _prefs.setString('last_reset_date', _lastResetDate.toIso8601String());
  }

  Future<void> _updateDailyNutrients(Map<String, dynamic> nutritionInfo) async {
    // Check if we need to reset before updating
    if (_lastResetDate.day != DateTime.now().day) {
      await _resetDailyNutrients();
    }

    setState(() {
      _dailyNutrients['calories'] = (_dailyNutrients['calories']! + nutritionInfo['calories'] as int);
      _dailyNutrients['fat'] = (_dailyNutrients['fat']! + nutritionInfo['fat'] as int);
      _dailyNutrients['carbs'] = (_dailyNutrients['carbs']! + nutritionInfo['carbs'] as int);
      _dailyNutrients['proteins'] = (_dailyNutrients['proteins']! + nutritionInfo['proteins'] as int);
    });

    await _prefs.setInt('daily_calories', _dailyNutrients['calories']!);
    await _prefs.setInt('daily_fat', _dailyNutrients['fat']!);
    await _prefs.setInt('daily_carbs', _dailyNutrients['carbs']!);
    await _prefs.setInt('daily_proteins', _dailyNutrients['proteins']!);

    // Update Supabase daily_nutrition table
    await _updateSupabaseDailyNutrition();
  }

  Future<void> _updateSupabaseDailyNutrition() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date in YYYY-MM-DD format

      // Try to update an existing record for today
      final updateResult = await supabase
          .from('daily_nutrition')
          .update({
            'daily_calories': _dailyNutrients['calories'],
            'daily_protein': _dailyNutrients['proteins'],
            'daily_fat': _dailyNutrients['fat'],
            'daily_carbs': _dailyNutrients['carbs'],
          })
          .match({'user_id': user.id, 'day': today})
          .select();

      // If no rows were affected, insert a new record
      if (updateResult.isEmpty) {
        await supabase
            .from('daily_nutrition')
            .insert({
              'user_id': user.id,
              'day': today,
              'daily_calories': _dailyNutrients['calories'],
              'daily_protein': _dailyNutrients['proteins'],
              'daily_fat': _dailyNutrients['fat'],
              'daily_carbs': _dailyNutrients['carbs'],
            });
      }

      print('Daily nutrition updated in Supabase');
    } catch (e) {
      print('Error updating daily nutrition in Supabase: $e');
      // Handle the error appropriately
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isModelLoading) {
      setState(() {
        _classificationResult = 'Model is still loading, please wait...';
      });
      return;
    }

    if (_interpreter == null) {
      setState(() {
        _classificationResult = 'Model failed to load, please restart the app.';
      });
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await _classifyImage(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _classificationResult = 'Error picking image: $e';
      });
    }
  }

  Future<void> _classifyImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

      if (image == null) {
        print('Failed to decode image');
        setState(() {
          _classificationResult = 'Failed to decode image';
        });
        return;
      }

      // Resize image to match model input size
      final img.Image resizedImage =
          img.copyResize(image, width: inputSize, height: inputSize);

      // Convert image to float32 array
      final input = _imageToByteListFloat32(resizedImage);

      // Reshape input to match model's expected shape
      final reshapedInput =
          input.reshape([batchSize, inputSize, inputSize, channels]);

      // Run inference
      final output = List.filled(13, 0.0).reshape([1, 13]);
      _interpreter!.run(reshapedInput, output);

      // Get the top result
      final result = output[0] as List<double>;
      final maxScore = result.reduce((a, b) => a > b ? a : b);
      final index = result.indexOf(maxScore);

      // TODO: Replace with your actual class labels
      final labels = [
        'ugali',
        'sukumawiki',
        'pilau',
        'nyamachoma',
        'mukimo',
        'matoke',
        'masalachips',
        'mandazi',
        'kukuchoma',
        'kachumbari',
        'githeri',
        'chapati',
        'bhajia'
      ]; // Example labels

      final identifiedFood = labels[index];

      setState(() {
        _classificationResult =
            'Classified as: $identifiedFood with confidence: ${maxScore.toStringAsFixed(2)}';
      });
      print(_classificationResult);

      // Call the edge function to get nutrition info
      await getFoodNutritionInfo(identifiedFood);
    } catch (e) {
      print('Error classifying image: $e');
      setState(() {
        _classificationResult = 'Error classifying image: $e';
      });
    }
  }

  Future<void> getFoodNutritionInfo(String foodName) async {
    try {
      final response = await supabase.functions.invoke(
        'food_nutrition_info',
        body: {'foodName': foodName},
      );

      if (response.status != 200) {
        throw Exception('Failed to get nutrition info: ${response.data}');
      }

      final nutritionInfo = response.data['data'] as Map<String, dynamic>;

      // Update daily nutrients
      await _updateDailyNutrients(nutritionInfo);

      // Display nutrition info in console
      print('Nutrition info for $foodName:');
      print('Calories: ${nutritionInfo['calories']}');
      print('Fat: ${nutritionInfo['fat']}');
      print('Carbs: ${nutritionInfo['carbs']}');
      print('Proteins: ${nutritionInfo['proteins']}');

      // Optionally, you can update the UI here as well
      setState(() {
        _classificationResult += '\n\nNutrition Info:' +
            '\nCalories: ${nutritionInfo['calories']}' +
            '\nFat: ${nutritionInfo['fat']}' +
            '\nCarbs: ${nutritionInfo['carbs']}' +
            '\nProteins: ${nutritionInfo['proteins']}';
        _classificationResult += '\n\nDaily Totals:' +
            '\nCalories so far: ${_dailyNutrients['calories']}' +
            '\nFat so far: ${_dailyNutrients['fat']}' +
            '\nCarbs so far: ${_dailyNutrients['carbs']}' +
            '\nProteins so far: ${_dailyNutrients['proteins']}';
      });
    } catch (e) {
      print('Error getting nutrition info: $e');
      // Optionally update UI to show error
      setState(() {
        _classificationResult += '\n\nFailed to get nutrition info';
      });
    }
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes =
        Float32List(batchSize * inputSize * inputSize * channels);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (pixel.r.toDouble() - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g.toDouble() - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b.toDouble() - 127.5) / 127.5;
      }
    }
    return convertedBytes;
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildDailyNutrientsCard(),
          _buildNewsItem(),
          _buildNewsItem(),
          // Add more news items as needed
          if (_classificationResult.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                _classificationResult,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourceDialog,
        child: Icon(Icons.camera_alt),
        tooltip: 'Take a photo of your meal',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 0, // Set to 0 for Feed
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Feed page, no action needed
              break;
            case 1:
              _showImageSourceDialog();
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildNewsItem() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Image.asset(
            'images/image_placeholder.png', // Replace with actual image
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200, // Adjust height as needed
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'News Headline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'News content preview...',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  child: Text('Read more'),
                  onPressed: () {
                    // TODO: Add code to dynamically fetch more news content and display them on a news page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyNutrientsCard() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Nutrient Totals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Calories so far: ${_dailyNutrients['calories']}'),
            Text('Fat so far: ${_dailyNutrients['fat']}'),
            Text('Carbs so far: ${_dailyNutrients['carbs']}'),
            Text('Proteins so far: ${_dailyNutrients['proteins']}'),
          ],
        ),
      ),
    );
  }
}