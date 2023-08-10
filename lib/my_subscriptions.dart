import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'globals.dart';

class MySubscriptions extends StatefulWidget {
  const MySubscriptions({Key? key}) : super(key: key);

  @override
  State<MySubscriptions> createState() => _MySubscriptionsState();
}

class _MySubscriptionsState extends State<MySubscriptions> {

  List<String> topics = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Moje subskrypcje'),
      ),
      body: ListView.builder(itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(space),
            child: Row(
              children: [
                Text(topics[index].replaceAll('%', ' ').replaceAll('_', ' > '),
                style: normal,),
              ],
            ),
          ),
        );
      },itemCount: topics.length),
    );
  }

  late StreamSubscription<DatabaseEvent> stream;

  @override
  void initState() {
    database = FirebaseDatabase.instance;
    database.useDatabaseEmulator(emulatorAddress, 9000);

    List<String> tempTopics = [];
    stream = database.ref('subscriptions/$user/topics').onValue.listen((event) {
      Map topicsMap = event.snapshot.value as Map;
      if(topicsMap.isNotEmpty){
       topicsMap.entries.forEach((e) {
         if(e.value){
           tempTopics.add(e.key);
         }
       });
      }

      setState(() {
        topics = tempTopics;
      });

    });
    super.initState();
  }

  @override
  void dispose() {
    stream.cancel();

    super.dispose();
  }
}
