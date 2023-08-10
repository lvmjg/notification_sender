import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_sender/dialogs.dart';
import 'package:notification_sender/panel_admin.dart';
import 'package:notification_sender/panel_user.dart';

import 'globals.dart';

class Login extends StatefulWidget {
  Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = '';

  String password = '';

  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Logowanie',
                    style: normal,
                  ),
                  SizedBox(
                    height: space * 2,
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3, color: Colors.blue), //<-- SEE HERE
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3, color: Colors.blue), //<-- SEE HERE
                      ),
                      labelStyle: MaterialStateTextStyle.resolveWith(
                          (states) => TextStyle(color: getColor(states))),
                      labelText: 'Email',
                      hintStyle: MaterialStateTextStyle.resolveWith(
                          (states) => TextStyle(color: getColor(states))),
                    ),
                  ),
                  SizedBox(
                    height: space,
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3, color: Colors.blue), //<-- SEE HERE
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3, color: Colors.blue), //<-- SEE HERE
                      ),
                      labelStyle: MaterialStateTextStyle.resolveWith(
                          (states) => TextStyle(color: getColor(states))),
                      labelText: 'Hasło',
                      hintStyle: MaterialStateTextStyle.resolveWith(
                          (states) => TextStyle(color: getColor(states))),
                    ),
                    onChanged: (value) => password = value,
                  ),
                  SizedBox(
                    height: space,
                  ),
                  OutlinedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(space * 2),
                      )),
                    ),
                    child: Text(
                      'Zaloguj',
                      style: normal,
                    ),
                    onPressed: () {

                      auth.signInWithEmailAndPassword(
                              email: emailController.text,
                              password: passwordController.text)
                          .then((value) {
                            user = auth.currentUser!.uid;

                            database.ref('users/' + user).onValue.listen((event) {
                              dynamic resultValue = event.snapshot.value;
                              if (resultValue != null) {
                                if (resultValue == "admin") {
                                  if (kIsWeb) {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => AdminPanel(title: 'Panel administratora')));
                                  } else {
                                  showErrorDialog(context, "Jako administrator musisz zalogować się na przeglądarce Chrome");
                                  }
                                } else {
                                  if(Platform.isAndroid) {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => UserPanel(title: 'Panel użytkownika')));
                                  } else {
                                    showErrorDialog(context, "Jako użytkownik musisz zalogować się na telefonie z systemem Android");
                                  }
                                }
                              }
                            });
                          }).catchError((error) => showErrorDialog(context, error));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
