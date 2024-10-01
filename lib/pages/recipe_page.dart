import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipePage extends StatefulWidget {
  final String mealName;

  const RecipePage({Key? key, required this.mealName}) : super(key: key);

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? recipeData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    try {
      final response = await supabase.functions.invoke(
        'get_recipe',
        body: {'mealName': widget.mealName},
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch recipe: ${response.data}');
      }

      setState(() {
        recipeData = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.mealName),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipeData!['name'],
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Image.network(recipeData!['image']),
                      SizedBox(height: 16),
                      Text('Source: ${recipeData!['source']}'),
                      InkWell(
                        child: Text('View full recipe', style: TextStyle(color: Colors.blue)),
                        onTap: () => launch(recipeData!['url']),
                      ),
                      SizedBox(height: 16),
                      Text('Calories: ${recipeData!['calories']}'),
                      Text('Total Time: ${recipeData!['totalTime']} minutes'),
                      SizedBox(height: 16),
                      Text('Diet Labels: ${recipeData!['dietLabels'].join(', ')}'),
                      Text('Health Labels: ${recipeData!['healthLabels'].join(', ')}'),
                      Text('Cautions: ${recipeData!['cautions'].join(', ')}'),
                      SizedBox(height: 16),
                      Text(
                        'Ingredients:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ...recipeData!['ingredientLines'].map((ingredient) => Text('• $ingredient')),
                      SizedBox(height: 16),
                      Text('Cuisine Type: ${recipeData!['cuisineType'].join(', ')}'),
                      Text('Meal Type: ${recipeData!['mealType'].join(', ')}'),
                      Text('Dish Type: ${recipeData!['dishType'].join(', ')}'),
                    ],
                  ),
                ),
    );
  }
}
