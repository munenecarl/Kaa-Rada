import 'package:flutter_bloc/flutter_bloc.dart';
import '../nutrition/nutrition_event.dart';

class NutritionState {
  final DailyNutrition dailyNutrition;
  final NutritionGoals nutritionGoals;

  NutritionState({required this.dailyNutrition, required this.nutritionGoals});

  NutritionState copyWith({
    DailyNutrition? dailyNutrition,
    NutritionGoals? nutritionGoals,
  }) {
    return NutritionState(
      dailyNutrition: dailyNutrition ?? this.dailyNutrition,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
    );
  }

  double getPercentage(double current, double goal) {
    return (current / goal * 100).clamp(0, 100);
  }

  double get caloriesPercentage => getPercentage(dailyNutrition.calories, nutritionGoals.caloriesGoal);
  double get proteinPercentage => getPercentage(dailyNutrition.protein, nutritionGoals.proteinGoal);
  double get fatPercentage => getPercentage(dailyNutrition.fat, nutritionGoals.fatGoal);
  double get carbsPercentage => getPercentage(dailyNutrition.carbs, nutritionGoals.carbsGoal);
}

class DailyNutrition {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  DailyNutrition({required this.calories, required this.protein, required this.fat, required this.carbs});
}

class NutritionGoals {
  final double caloriesGoal;
  final double proteinGoal;
  final double fatGoal;
  final double carbsGoal;

  NutritionGoals({required this.caloriesGoal, required this.proteinGoal, required this.fatGoal, required this.carbsGoal});
}
