import 'dart:convert';

import 'package:flutter_ketor/model/food.dart';
import 'package:http/http.dart' as http;

// server address and port for emulator
const URL = '10.0.2.2:2019';

class API {
  static Future<http.Response> getAllFoodsAPI() async {
    return await http.get(new Uri.http(URL, '/api/foods'));
  }

  static Future<http.Response> addFoodAPI(Food food) async {
    return await http.post(new Uri.http(URL, '/api/food'),
        body: jsonEncode(food.toMap()), headers: {"Content-Type": "application/json"});
  }

  static Future<http.Response> updateFoodAPI(Food food) async {
    return await http.put(new Uri.http(URL, '/api/food/${food.id}'),
        body: jsonEncode(food.toMap()), headers: {"Content-Type": "application/json"});
  }

  static deleteFoodAPI(int id) async {
    return await http.delete(new Uri.http(URL, '/api/food/$id'));
  }
}
