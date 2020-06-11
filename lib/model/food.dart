import 'food_contract.dart';

class Food {
  int id;
  String name;
  String level;
  String kcal;
  String fats;
  String carbs;
  String protein;

  Food({this.id, this.name, this.level, this.kcal, this.fats, this.carbs, this.protein});

  Food.newFood(this.id, this.name, this.level, this.kcal, this.fats, this.carbs, this.protein);

  factory Food.fromMap(Map<String, dynamic> json) => new Food(
      id: json[FoodContract.COL_ID],
      name: json[FoodContract.COL_NAME],
      level: json[FoodContract.COL_LEVEL],
      kcal: json[FoodContract.COL_KCAL].toString(),
      fats: json[FoodContract.COL_FATS].toString(),
      carbs: json[FoodContract.COL_CARBS].toString(),
      protein: json[FoodContract.COL_PROTEIN].toString());

  Map<String, dynamic> toMap() => {
        FoodContract.COL_ID: this.id,
        FoodContract.COL_NAME: this.name,
        FoodContract.COL_LEVEL: this.level,
        FoodContract.COL_KCAL: this.kcal,
        FoodContract.COL_FATS: this.fats,
        FoodContract.COL_CARBS: this.carbs,
        FoodContract.COL_PROTEIN: this.protein
      };

  String nutrients() {
    return "$kcal kcal - fats:${fats}g, carbs:${carbs}g, protein:${protein}g";
  }
}
