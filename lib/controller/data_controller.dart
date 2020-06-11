import 'dart:async';
import 'dart:collection';

import 'package:flutter_ketor/local_db/local_db.dart';
import 'package:flutter_ketor/model/food.dart';
import 'package:flutter_ketor/networking/api_client.dart';
import 'package:flutter_ketor/utils/utils.dart';

class DataController {
  ApiClient apiClient; // api connection
  LocalDbManager localDb; // local db connection

  Queue<Food> addedFoods; // foods added offline

  DataController() {
    apiClient = ApiClient();
    localDb = LocalDbManager.db;
    addedFoods = Queue();
  }

  // called when receives an item via a websocket broadcast
  void webSocketUpdate(Food element, String action) async {
    // check if we have the elem
    List<Food> localFoods = await localDb.queryAll();
    int index = localFoods.indexWhere((f) => f.id == element.id);

    if (action == "INSERT" && index < 0) {
      localDb.insert(element);
    } else if (action == "UPDATE" && index >= 0) {
      localDb.update(element);
    } else if (action == "DELETE" && index >= 0) {
      localDb.delete(element.id);
    }
    print("performed the broadcasted $action on: ${element.id}, ${element.name}");
  }

  // try again pushing offline added foods to the server
  void tryPushOnline() {
    int lingeringSize = addedFoods.length;
    isOnline().then((haveConnection) {
      // only do this if online and things to push
      if (haveConnection != null && haveConnection && lingeringSize > 0) {
        while (addedFoods.isNotEmpty) {
          Food curFood = addedFoods.removeFirst();
          // remove it locally since the correct id version will come back via the socket
          localDb.delete(curFood.id);
          apiClient.save(curFood);
        }
        print("pushed $lingeringSize lingering foods to the server");
      }
    });
  }

  // no need to always fetch from the server
  Future<List<Food>> updateFoodList() async {
    return localDb.queryAll();
  }

  // fetch from the server, if possible
  Future<List<Food>> getFoods() async {
    tryPushOnline();
    List<Food> result = await isOnline().then((haveConnection) async {
      if (haveConnection != null && haveConnection) {
        print("items fetched from server");
        List<Food> foods = await apiClient.getAllFoods();
        localDb.deleteAll();
        foods.forEach((f) => localDb.insert(f));
        return foods;
      } else {
        return localDb.queryAll();
      }
    });
    return result;
  }

  // push an item to the server or save it just locally and in the offline-queue
  Future<int> save(Food food) async {
    Food returnFood = food;
    int result = await isOnline().then((haveConnection) async {
      if (haveConnection != null && haveConnection) {
        returnFood.id = await apiClient.save(food);
        //localDb.insert(returnFood); // websocket will handle local saving
        print("pushed ${returnFood.name} to the server");
        return returnFood.id;
      } else {
        returnFood.id = await localDb.insert(food, true);
        addedFoods.add(returnFood);
        print("saved ${returnFood.name} locally");
        return -2;
      }
    });
    return result;
  }

  // update a food, if online
  Future<int> update(Food food) async {
    int result = await isOnline().then((haveConnection) async {
      if (haveConnection != null && haveConnection) {
        int result = await apiClient.update(food);
        //await localDb.update(food); // websocket will handle local saving
        print("updated ${food.name}");
        return result;
      }
      return -2;
    });
    return result;
  }

  // delete a food, if online
  Future<int> delete(int id) async {
    int result = await isOnline().then((haveConnection) async {
      if (haveConnection != null && haveConnection) {
        int result = await apiClient.delete(id);
        //await localDb.delete(id); // websocket will handle local saving
        print("deleted $id");
        return result;
      }
      return -2;
    });
    return result;
  }
}
