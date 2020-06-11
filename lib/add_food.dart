import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ketor/controller/data_controller.dart';

import 'model/food.dart';

class AddFoodDialog extends StatefulWidget {
  final DataController manager;

  // food data
  final int id;
  final String name;
  final String level;
  final String kcal;
  final String fats;
  final String carbs;
  final String protein;

  AddFoodDialog({this.manager, this.id, this.name, this.level, this.kcal, this.fats, this.carbs, this.protein});

  @override
  _AddFoodDialogState createState() => _AddFoodDialogState(this.manager);
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formAddFoodKey = GlobalKey<FormState>();
  final DataController dataController;

  // food data editing
  String _name;
  String _level;
  String _kcal;
  String _fats;
  String _carbs;
  String _protein;

  // radio button state and handler
  @override
  void initState() {
    setState(() {
      _level = widget.level != null && widget.level.isNotEmpty ? widget.level : "High";
    });
    super.initState();
  }

  void radioButtonChanges(String value) {
    setState(() {
      _level = value;
    });
  }

  _AddFoodDialogState(this.dataController);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              final form = _formAddFoodKey.currentState;
              if (form.validate()) {
                form.save();
                // if we had a name by default, its an update
                if (widget.name != null && widget.name.isNotEmpty) {
                  var food = Food.newFood(widget.id, _name, _level, _kcal, _fats, _carbs, _protein);
                  dataController.update(food).then((id) {
                    food.id = id;
                    Navigator.pop(context, food);
                  });
                } else {
                  // else its a new item to be added
                  var food = Food.newFood(0, _name, _level, _kcal, _fats, _carbs, _protein);
                  dataController.save(food).then((result) {
                    Navigator.pop(context, result);
                  });
                }
              }
            },
            child: Text(
              widget.name != null && widget.name.isNotEmpty ? "UPDATE" : 'SAVE',
              style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Form(
            key: _formAddFoodKey,
            // scrollable form with all the fields
            child: ListView(physics: ScrollPhysics(), shrinkWrap: true, children: [
              textFormField("name", Icons.title, false, (value) => _name = value,
                  widget.name != null && widget.name.isNotEmpty ? widget.name : ""),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                  Text("level: "),
                  Radio(
                    value: 'High',
                    groupValue: _level,
                    onChanged: radioButtonChanges,
                  ),
                  Text("High"),
                  Radio(
                    value: 'Medium',
                    groupValue: _level,
                    onChanged: radioButtonChanges,
                  ),
                  Text("Medium"),
                  Radio(
                    value: 'Low',
                    groupValue: _level,
                    onChanged: radioButtonChanges,
                  ),
                  Text("Low"),
                ]),
              ),
              textFormField("kcal", Icons.filter_1, true, (value) => _kcal = value,
                  widget.kcal != null && widget.kcal.isNotEmpty ? widget.kcal : ""),
              textFormField("fats", Icons.filter_2, true, (value) => _fats = value,
                  widget.fats != null && widget.fats.isNotEmpty ? widget.fats : ""),
              textFormField("carbs", Icons.filter_3, true, (value) => _carbs = value,
                  widget.carbs != null && widget.carbs.isNotEmpty ? widget.carbs : ""),
              textFormField("protein", Icons.filter_4, true, (value) => _protein = value,
                  widget.protein != null && widget.protein.isNotEmpty ? widget.protein : ""),
            ])),
      ),
    );
  }

  Padding textFormField(String label, IconData icon, bool number, Function onSaved, String initValue) {
    return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            prefixIcon: Icon(icon),
          ),
          // don't let specific fields get non-digit values
          inputFormatters: number ? [WhitelistingTextInputFormatter.digitsOnly] : [],
          keyboardType: number ? TextInputType.numberWithOptions(signed: false, decimal: false) : TextInputType.text,
          initialValue: initValue,
          // no empty fields can be committed
          validator: (value) {
            return validateStuff(value);
          },
          onSaved: onSaved,
        ));
  }

  // no empty fields can be committed
  String validateStuff(String value) {
    if (value.isEmpty) {
      return "no empty fields";
    } else {
      return null;
    }
  }
}
