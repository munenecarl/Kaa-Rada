import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../nutrition/nutrition_event.dart';
import '../nutrition/nutrition_state.dart';

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  NutritionBloc() : super(NutritionState(
    dailyNutrition: DailyNutrition(calories: 0, protein: 0, fat: 0, carbs: 0),
    nutritionGoals: NutritionGoals(caloriesGoal: 0, proteinGoal: 0, fatGoal: 0, carbsGoal: 0)
  )) {
    _initializeNutritionData();

    on<UpdateDailyNutrition>((event, emit) {
      emit(state.copyWith(dailyNutrition: event.nutrition));
      _saveDailyNutrition(event.nutrition);
    });

    on<UpdateNutritionGoals>((event, emit) {
      emit(state.copyWith(nutritionGoals: event.goals));
    });
  }

  Future<void> _initializeNutritionData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Fetch and calculate daily goals
    final weeklyCalories = prefs.getInt('weekly_calories') ?? 14000;
    final weeklyProtein = prefs.getInt('weekly_protein') ?? 350;
    final weeklyFat = prefs.getInt('weekly_fat') ?? 490;
    final weeklyCarbs = prefs.getInt('weekly_carbs') ?? 2100;

    final goals = NutritionGoals(
      caloriesGoal: weeklyCalories / 7,
      proteinGoal: weeklyProtein / 7,
      fatGoal: weeklyFat / 7,
      carbsGoal: weeklyCarbs / 7,
    );

    // Fetch daily totals
    final dailyCalories = prefs.getInt('daily_calories') ?? 0;
    final dailyProtein = prefs.getInt('daily_proteins') ?? 0;
    final dailyFat = prefs.getInt('daily_fat') ?? 0;
    final dailyCarbs = prefs.getInt('daily_carbs') ?? 0;

    final dailyNutrition = DailyNutrition(
      calories: dailyCalories.toDouble(),
      protein: dailyProtein.toDouble(),
      fat: dailyFat.toDouble(),
      carbs: dailyCarbs.toDouble(),
    );

    add(UpdateNutritionGoals(goals));
    add(UpdateDailyNutrition(dailyNutrition));
  }

  Future<void> _saveDailyNutrition(DailyNutrition nutrition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_calories', nutrition.calories.round());
    await prefs.setInt('daily_proteins', nutrition.protein.round());
    await prefs.setInt('daily_fat', nutrition.fat.round());
    await prefs.setInt('daily_carbs', nutrition.carbs.round());
  }
}
