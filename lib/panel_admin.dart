import 'dart:async';
import 'dart:core';
import 'dart:core';
import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_sender/panel_login.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';

import 'dialogs.dart';
import 'globals.dart';
import 'item.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key, required this.title});

  final String title;

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  StreamSubscription<DatabaseEvent>? stream;

  List<Item> itemsPath = [];
  List<Item> sourceItems = [];
  List<Item> filteredItems = [];
  List<String> subsribedTopics = [];

  bool allowSubscription = true;

  late TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        flexibleSpace: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                auth.signOut().then((value) => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => Login())));
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  child: Icon(Icons.logout,
                  color: Colors.white,),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddItemDialog();
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: Padding(
                padding: EdgeInsets.all(space * 2),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Filtruj...',
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        filteredItems = sourceItems;
                      });
                    } else {
                      List<Item> tempItems = sourceItems
                          .where((e) => e.name
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();

                      setState(() {
                        filteredItems = tempItems;
                      });
                    }
                  },
                ),
              )),
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height / 17,
            child: Expanded(
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.all(space / 2),
                      child: ActionChip(
                        backgroundColor: Colors.blue,
                        avatar: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        label: Padding(
                          padding: EdgeInsets.all(space / 2),
                          child: Text(
                            itemsPath[index].name,
                            style: smallWhite,
                          ),
                        ),
                        onPressed: () {
                          itemsPath = itemsPath.take(index + 1).toList();
                          loadLevel();
                        },
                      ),
                    );
                  },
                  itemCount: itemsPath.isEmpty
                      ? itemsPath.length
                      : itemsPath.length - 1),
            ),
          ),
          SizedBox(height: space),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(space),
                child: Text(
                  itemsPath.last.name,
                  style: smallGrey,
                ),
              )),
          SizedBox(height: space),
          Expanded(
              child: ListView.builder(
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  itemsPath.add(filteredItems[index]);
                  loadLevel();
                },
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(space),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          filteredItems[index].name,
                          style: normal,
                        ),
                        SizedBox(
                          width: space,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible: filteredItems[index].subscribable,
                                child: OutlinedButton.icon(
                                  icon: Text('Usuń'),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(space * 2),
                                    )),
                                  ),
                                  onPressed: () {
                                    removeItem(filteredItems[index]);
                                  },
                                  label: Icon(Icons.delete),
                                ),
                              ),
                              Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible: filteredItems[index].subscribable,
                                child: OutlinedButton.icon(
                                  icon: Text('Powiadom'),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(space * 2),
                                    )),
                                  ),
                                  onPressed: () {
                                    showCreateNotificationDialog(
                                        filteredItems[index]);
                                  },
                                  label: Icon(Icons.message),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            itemCount: filteredItems.length,
          )),
        ],
      ),
    );
  }

  @override
  void initState() {
    loadLevel();

    database.ref('subscriptions/$user/topics').onValue.listen((event) {
      Map topicsMap = event.snapshot.value as Map;
      if (topicsMap.isNotEmpty) {
        List<String> tempSubscribedTopics = topicsMap.entries
            .where((e) => e.value)
            .map((e) => e.key as String)
            .toList();
        setState(() {
          subsribedTopics = tempSubscribedTopics;
        });
      }
    });

    super.initState();

    controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadLevel() {
    if (stream != null) {
      stream?.cancel();
    }

    if(itemsPath.isEmpty){
      itemsPath.add(Item('init', 'Str. główna', false));
    }

    String levelPath = 'levels/level_${itemsPath.length}/${itemsPath.last.key}';

    List<Item> tempItems = [];
    stream = database.ref(levelPath).onValue.listen((event) {
      dynamic resultValue = event.snapshot.value;

      if(resultValue!=null) {
        Map mapItems = resultValue as Map;
        tempItems = mapItems.entries.map((e) => Item.fromJson(e.key, e.value)).toList();
      }

      tempItems.sort((a,b)=> a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        sourceItems = tempItems;
        filteredItems = tempItems;
      });
    });
  }

  void showAddItemDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Dodaj kategorię'),
            content: StatefulBuilder(builder: (BuildContext context,
                void Function(void Function()) setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Column(
                      children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Nazwa')),
                        SizedBox(
                          height: space,
                        ),
                        TextField(
                          controller: nameController,
                        ),
                        SizedBox(
                          height: space,
                        ),
                        Row(children: [
                          Text('Subskrybcja'),
                          SizedBox(
                            width: space,
                          ),
                          Switch(
                            onChanged: (value) {
                              allowSubscription = value;

                              setState(() {});
                            },
                            value: allowSubscription,
                          )
                        ])
                      ],
                    )
                  ],
                ),
              );
            }),
            actions: [
              TextButton(
                child: Text('Dodaj'),
                onPressed: () {
                  String newTopic = nameController.text.trim();

                  bool isValidTopic = RegExp(r'^[a-zA-Z0-9- ]{1,50}$').hasMatch(newTopic);
                  if (isValidTopic) {
                    addItem(newTopic, allowSubscription);
                    Navigator.of(context).pop();
                  } else {
                    String error = 'Kategoria powinna zawierać tylko znaki A-Z, cyfry 0-9 i spacje. Polskie znaki są niedozwolone.';
                    showErrorDialog(context, error);
                  }
                },
              ),
            ],
          );
        });
  }

  void addItem(String name, bool allowSubscription) {
    int parentLevel = itemsPath.length;
    String parentKey = itemsPath.last.key;

    String levelPath = 'levels/level_$parentLevel/$parentKey';

    String? childKey = database.ref(levelPath).push().key;
    if (childKey != null) {
      Map<String, dynamic> updates = {};
      updates['$levelPath/$childKey'] = {
        "name": name,
        "subscribable": allowSubscription
      };

      database
          .ref()
          .update(updates)
          .catchError((onError) => showErrorDialog(context, onError));
    }
  }

  Future<void> removeItem(Item next) async {
    List<String> toDelete = [];

    String root = 'levels/level_${itemsPath.length}/${itemsPath.last.key}/${next.key}';
    toDelete.add(root);

    int index = itemsPath.length + 1;
    String parent = next.key;
    await loadRecursive(index, parent, toDelete);

    Map<String, dynamic> updates = {};
    toDelete.forEach((element) {
      updates[element] = {};
    });

    database
        .ref()
        .update(updates)
        .catchError((onError) => showErrorDialog(context, onError))
        .then((value) {
            loadLevel();
        });
  }

  Future<void> loadRecursive(index, parent, toDelete) async {
    String root = 'levels/level_$index/$parent';
    DataSnapshot snapshot = await database.ref(root).get();
    dynamic result = snapshot.value;
    if (result != null) {
      Map childs = result as Map;
      index++;
      childs.keys.forEach((element) {
        toDelete.add('$root/' + element);
      });

      for (var element in childs.keys) {
        await loadRecursive(index, element, toDelete);
      }
    }
  }

  void showCreateNotificationDialog(Item target) {
    TextEditingController nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Powiadom użytkowników'),
            content: SingleChildScrollView(
              child: ListBody(children: [
                Text('Treść wiadomości'),
                SizedBox(
                  height: space,
                ),
                TextField(
                  controller: nameController,
                ),
              ]),
            ),
            actions: [
              TextButton(
                child: Text('Wyślij'),
                onPressed: () {
                  sendMessage(target, nameController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void sendMessage(Item target, String text) {
    String topic = createTopic(target.name, itemsPath);
    database.ref('messages/$topic')
        .push()
        .set({"message": text, "date": DateTime.now().toString()}).then((value) {

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Wiadomość została dodana do bazy')));

        }).catchError((error) {

          showErrorDialog(context,error);

        });
  }
}
