import '../nutrition/nutrition_state.dart';

abstract class NutritionEvent {}

class UpdateDailyNutrition extends NutritionEvent {
  final DailyNutrition nutrition;
  UpdateDailyNutrition(this.nutrition);
}

class UpdateNutritionGoals extends NutritionEvent {
  final NutritionGoals goals;
  UpdateNutritionGoals(this.goals);
}
