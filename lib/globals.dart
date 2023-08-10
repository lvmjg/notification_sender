import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

late FirebaseDatabase database;
late FirebaseAuth auth;

String user = '';

BehaviorSubject messageStreamController = BehaviorSubject<RemoteMessage>();

String emulatorAddress = kIsWeb ? 'localhost' : '10.0.2.2';

double space = 9;

TextStyle small = TextStyle(fontSize: 12, color: Colors.black87,);
TextStyle smallWhite = TextStyle(fontSize: 12, color: Colors.white);
TextStyle smallBlue = TextStyle(fontSize: 12, color: Colors.blue);
TextStyle smallGrey = TextStyle(fontSize: 12, color: Colors.black54);

TextStyle normal = TextStyle(fontSize: 16, color: Colors.black);
TextStyle normalWhite = TextStyle(fontSize: 16, color: Colors.white);
TextStyle normalGreen = TextStyle(fontSize: 16, color: Colors.green);
TextStyle normalRed = TextStyle(fontSize: 16, color: Colors.red);
TextStyle normalBlue = TextStyle(fontSize: 16, color: Colors.blue);

TextStyle normalGrey = TextStyle(fontSize: 16, color: Colors.black54);

Color getColor(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blueGrey.shade500;
  }

  if (states.contains(MaterialState.disabled)) {
    return Colors.blueGrey.shade100;
  }

  return Colors.blueGrey.shade300;
}