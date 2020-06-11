import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../model/food.dart';
import '../model/food_contract.dart';

class LocalDbManager {
  // singleton
  LocalDbManager._();
  static final LocalDbManager db = LocalDbManager._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "FlutterFoods.db");
    return await openDatabase(path, version: 1, onOpen: (db) {}, onCreate: (Database db, int version) async {
      await db.execute("""CREATE TABLE ${FoodContract.DB_TABLE} (
          ${FoodContract.COL_ID} INTEGER PRIMARY KEY,
          ${FoodContract.COL_NAME} TEXT,
          ${FoodContract.COL_LEVEL} TEXT,
          ${FoodContract.COL_KCAL} TEXT,
          ${FoodContract.COL_FATS} TEXT,
          ${FoodContract.COL_CARBS} TEXT,
          ${FoodContract.COL_PROTEIN} TEXT);
        """);
    });
  }

  Future<int> insert(Food food, [bool offline = false]) async {
    final db = await database;
    if (offline) {
      //get the biggest id in the table
      var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM ${FoodContract.DB_TABLE}");
      food.id = table.first[FoodContract.COL_ID] + 1;
    }
    print("DB INSERT: ${food.id}, offline: $offline");
    return await db.rawInsert("""INSERT INTO ${FoodContract.DB_TABLE} (
      ${FoodContract.COL_ID},
      ${FoodContract.COL_NAME},
      ${FoodContract.COL_LEVEL},
      ${FoodContract.COL_KCAL},
      ${FoodContract.COL_FATS},
      ${FoodContract.COL_CARBS},
      ${FoodContract.COL_PROTEIN}) VALUES(?,?,?,?,?,?,?)""",
        [food.id, food.name, food.level, food.kcal, food.fats, food.carbs, food.protein]);
  }

  queryOne(int id) async {
    final db = await database;
    var res = await db.query(FoodContract.DB_TABLE, where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Food.fromMap(res.first) : null;
  }

  Future<List<Food>> queryAll() async {
    final db = await database;
    var res = await db.query(FoodContract.DB_TABLE);
    List<Food> list = res.isNotEmpty ? res.map((c) => Food.fromMap(c)).toList() : [];
    return list;
  }

  Future<int> update(Food food) async {
    final db = await database;
    print("DB UPDATE: ${food.id}");
    return await db.update(FoodContract.DB_TABLE, food.toMap(), where: "id = ?", whereArgs: [food.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    print("DB DELETE: $id");
    return db.delete(FoodContract.DB_TABLE, where: "id = ?", whereArgs: [id]);
  }

  void deleteAll() async {
    final db = await database;
    await db.execute("DELETE FROM ${FoodContract.DB_TABLE} ");
  }
}
