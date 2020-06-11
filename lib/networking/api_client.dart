import 'dart:convert';

import 'package:flutter_ketor/model/food.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

class ApiClient {
  Future<List<Food>> getAllFoods() async {
    http.Response response = await API.getAllFoodsAPI();
    if (response == null) return List<Food>();
    Iterable list = json.decode(response.body);
    List<Food> foods = list.map((model) => Food.fromMap(model)).toList();
    return foods;
  }

  Future<int> save(Food food) async {
    http.Response response = await API.addFoodAPI(food);
    Food returnFood = Food.fromMap(json.decode(response.body));
    return returnFood.id;
  }

  Future<int> update(Food food) async {
    http.Response response = await API.updateFoodAPI(food);
    Food returnFood = Food.fromMap(json.decode(response.body));
    return returnFood.id;
  }

  Future<int> delete(int id) async {
    http.Response response = await API.deleteFoodAPI(id);
    return id;
  }
}
