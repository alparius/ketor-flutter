import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ketor/controller/data_controller.dart';
import 'package:flutter_ketor/networking/api.dart';
import 'package:flutter_ketor/utils/utils.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'add_food.dart';
import 'model/food.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutterKetor',
      theme: ThemeData(
        brightness: Brightness.dark,
        splashColor: Colors.black12,
        primaryColor: Colors.teal,
        accentColor: Colors.teal,
        fontFamily: 'Raleway',
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  DataController dataController; // controller access
  Future<List<Food>> _items; // content to display

  WebSocket ws; // broadcast listener
  bool listening; // to decide on listener recreation

  // controller so that only one item can have its slidable opened at a time
  final SlidableController slidableController = new SlidableController();

  // so snackbars can be created anywhere
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    dataController = DataController();
    _items = dataController.getFoods();
    listening = false;
    _wsListen();
  }

  // small update from local db
  updateList() {
    setState(() {
      _items = dataController.updateFoodList();
    });
  }

  // big update from server - only tied to the "refresh" button
  refreshList() {
    setState(() {
      if (!listening) {
        _wsListen();
      }
      _items = dataController.getFoods();
    });
  }

  // broadcast listener
  _wsListen() async {
    // we need to always recreate the listener
    // but never create multiple listeners
    if (listening) return;
    listening = true;
    try {
      ws = await WebSocket.connect("ws://$URL");
    } catch (e) {
      listening = false;
      print("@@ error: $e");
      return;
    }
    ws.listen(
        (data) {
          // handle the received action
          Map<String, dynamic> jsonData = Map<String, dynamic>.from(json.decode(data.toString()));
          dataController.webSocketUpdate(Food.fromMap(jsonData), jsonData["action"] as String);
          Future.delayed(const Duration(milliseconds: 500), () {
            updateList();
          });
        },
        cancelOnError: true,
        // try to reconnect after offline periods
        onDone: () {
          listening = false;
          ws = null;
          Timer.periodic(Duration(seconds: 10), (Timer timer) async {
            try {
              await _wsListen();
            } catch (e) {
              print("@@ error: $e");
            }
            if (ws != null) timer.cancel();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    // the + FAB to add a new food
    return Scaffold(
      key: _scaffoldKey, // so snackbars can be created anywhere
      body: SafeArea(child: _buildBody(context)),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(65.0),
        child: AppBar(
          title: _getAppBarTitle(),
          actions: <Widget>[
            RawMaterialButton(
              onPressed: () {
                refreshList();
              },
              child: Icon(Icons.refresh),
            ),
            RawMaterialButton(
              onPressed: () {
                _showInfo();
              },
              child: Icon(Icons.info),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddFood();
          updateList();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<Food>>(
      stream: _items.asStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Food>> snapshot) {
        if (snapshot.hasData) {
          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildFoodList(context, snapshot.data),
              ],
            ),
          );
        } else {
          // if all foods have been deleted
          return Center(
            child: Text(
              "Add foods with the + button.",
              style: Theme.of(context).textTheme.title,
            ),
          );
        }
      },
    );
  }

  Widget _buildFoodList(BuildContext context, List<Food> items) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListView(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 20.0),
            children: items.map((item) => _buildFoodItem(context, item)).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, Food food) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable.builder(
        // no two items can have their slidable open at the same time
        controller: slidableController,
        secondaryActionDelegate: new SlideActionListDelegate(actions: null),
        // sliding right
        actionDelegate: new SlideActionBuilderDelegate(
            actionCount: 2,
            builder: (context, index, animation, renderingMode) {
              // the edit button on the second position
              if (index == 1) {
                return new IconSlideAction(
                  caption: 'Edit',
                  color: Colors.blue,
                  icon: Icons.edit,
                  onTap: () => _navigateToUpdateFood(food),
                  closeOnTap: false,
                );
              } else {
                // the delete button on the first pos of the slider
                return new IconSlideAction(
                  caption: 'Delete',
                  closeOnTap: false,
                  color: Colors.red,
                  icon: Icons.delete,
                  // deletion needs to be confirmed
                  onTap: () => _dialogToDeleteFood(context, food.id),
                );
              }
            }),
        key: Key(food.id.toString()),
        // the list content itself: title and subtitle
        child: ListTile(
          title: Text(
            food.name,
            style: TextStyle(color: levelColors[food.level]),
          ),
          subtitle: Text(food.nutrients()),
          // show some help with an icon and a snackbar if sliding is not obvious
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            makeSnackBar("swipe left for actions");
          },
        ),
        actionPane: SlidableDrawerActionPane(),
      ),
    );
  }

  // create a snackbar. Anywhere
  ScaffoldState makeSnackBar(String message) {
    return _scaffoldKey.currentState
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // route and callback handler to add a new food action
  void _navigateToAddFood() async {
    int result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFoodDialog(
          manager: this.dataController,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result !=null && result > 0) {
      updateList();
    } else if (result !=null && result == -2) {
      makeSnackBar("but you are offline! (will sync later)");
      updateList();
    }
  }

  // route and callback handler to update a food action
  void _navigateToUpdateFood(Food food) async {
    Food result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFoodDialog(
          id: food.id,
          name: food.name,
          level: food.level,
          kcal: food.kcal,
          fats: food.fats,
          carbs: food.carbs,
          protein: food.protein,
          manager: this.dataController,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result !=null && result.id > 0) {
      updateList();
    } else if (result !=null && result.id == -2) {
      makeSnackBar("but you are offline!");
    }
  }

  // dialog and handler for deleting a food
  Future<bool> _dialogToDeleteFood(BuildContext context, int id) {
    // item removal confirmation dialog
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete'),
          content: Text('Food will be deleted'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FlatButton(
              child: Text('Delete'),
              onPressed: () async {
                await dataController.delete(id).then((id) {
                  if (id > 0) {
                    updateList();
                  } else {
                    makeSnackBar("but you are offline!");
                  }
                  Navigator.of(context).pop(true);
                });
              },
            ),
          ],
        );
      },
    );
  }

  // fancy title and subtitle
  Padding _getAppBarTitle() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(
          "flutterKetor",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        Text(
          "user-friendly list of keto-friendly foods",
          style: TextStyle(fontSize: 16),
        ),
      ]),
    );
  }

  // the stateless showinfo activity
  void _showInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(65.0),
            child: AppBar(
              title: _getAppBarTitle(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 8),
            child: Container(
              child: Text(
                "The ketogenic diet is a very low-carb, high-fat diet that shares many similarities with the Atkins and low-carb diets.\n\nIt involves drastically reducing carbohydrate intake and replacing it with fat. This reduction in carbs puts your body into a metabolic state called ketosis.\n\nWhen this happens, your body becomes incredibly efficient at burning fat for energy. It also turns fat into ketones in the liver, which can supply energy for the brain.\n\nKetogenic diets can cause massive reductions in blood sugar and insulin levels. This, along with the increased ketones, has numerous health benefits.",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
