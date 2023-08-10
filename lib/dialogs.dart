import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String error){
  showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          title: Text('Błąd'),
          content: Text(error),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                child: const Text('Ok'),
              ),
            ),
          ])
  );
}