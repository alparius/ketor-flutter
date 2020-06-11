import 'dart:async';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';

// return true if there's a server connection
Future<bool> isOnline() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

// mapping of keto-levels to display colors
const Map<String, Color> levelColors = {"High": Colors.green, "Medium": Colors.amber, "Low": Colors.red};
