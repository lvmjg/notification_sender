import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_sender/main.dart';
import 'package:notification_sender/panel_login.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';
import 'package:flutter/foundation.dart';
import 'dialogs.dart';
import 'globals.dart';
import 'item.dart';
import 'my_subscriptions.dart';

class UserPanel extends StatefulWidget {
  const UserPanel({super.key, required this.title});

  final String title;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  StreamSubscription<DatabaseEvent>? stream;

  List<Item> itemsPath = [];
  List<Item> sourceItems = [];
  List<Item> filteredItems = [];
  List<String> subsribedTopics = [];

  _UserPanelState() {
    if (!kIsWeb) {
      messageStreamController.listen((message) {
        Map lastData = message.data;

        showMessageDialog(lastData);
      });
    }
  }

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
      floatingActionButton: FloatingActionButton.extended(
        icon: Text('Moje subskrypcje'),
        label: Icon(Icons.notifications_active),
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => MySubscriptions()));
        },
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
                  itemsPath.length ==0 ? "Str. główna" : itemsPath.last.name,
                  style: smallGrey,
                ),
              )),
          SizedBox(height: space),
          Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          filteredItems[index].name,
                          style: normal,
                        ),
                        Visibility(
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          visible: isSubscribed(filteredItems[index].name)
                              ? true
                              : (isParentSubsribed()
                                  ? false
                                  : filteredItems[index].subscribable
                                ),
                          child: OutlinedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(space * 2),
                              )),
                            ),
                            child: Text(isSubscribed(filteredItems[index].name)
                                ? 'Anuluj subskrypcję'
                                : 'Subskrybuj'),
                            onPressed: () {
                              trySubscribe(filteredItems[index].name);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },

          )),
        ],
      ),
    );
  }

  @override
  void initState() {
    loadLevel();

    database.ref('subscriptions/$user/topics').onValue.listen((event) {
      dynamic topics = event.snapshot.value;
      if (topics != null) {
        Map topicsMap = topics as Map;
        if (topicsMap.isNotEmpty) {
          List<String> tempSubscribedTopics = topicsMap.entries
              .where((e) => e.value)
              .map((e) => e.key as String)
              .toList();
          setState(() {
            subsribedTopics = tempSubscribedTopics;
          });
        }
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
      print('test');
      dynamic e = event;
      dynamic rr = event.snapshot;
      dynamic resultValue = event.snapshot.value;

      if(resultValue!=null) {
        Map mapItems = resultValue as Map;
        tempItems = mapItems.entries.map((e) => Item.fromJson(e.key, e.value)).toList();
      } else {
        if(itemsPath.length>1) {
          itemsPath = itemsPath.take(itemsPath.length - 1).toList();
        }
        tempItems = filteredItems;
      }

      tempItems.sort((a,b)=> a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        sourceItems = tempItems;
        filteredItems = tempItems;
      });
    });
  }

  bool isParentSubsribed() {
    bool subsribed = false;
    List<Item> reduced = itemsPath.skip(1).toList();

    String topic = '';
    for (Item r in reduced) {
      topic += r.name;

      subsribed = subsribedTopics.contains(topic);

      if (subsribed) {
        break;
      }

      topic += '_';
    }

    return subsribed;
  }

  bool isSubscribed(String key) {
    String topic = createTopic(key, itemsPath);
    return subsribedTopics.contains(topic);
  }

  void trySubscribe(String key) {
    String topic = createTopic(key, itemsPath);
    if (subsribedTopics.contains(topic)) {
      unSubscribeFromTopic(topic);
    } else {
      subscribeOnTopic(topic);
    }
  }

  void subscribeOnTopic(String topic) {
    FirebaseMessaging.instance.subscribeToTopic(topic).then((value) {
      DatabaseReference ref = database.ref('topics');
      stream = ref.orderByValue().equalTo(topic).onValue.listen((event) {
        dynamic newTopic = event.snapshot.value;
        if (newTopic == null) {
          database.ref('topics').push().set(topic).then((value) {
            database.ref('subscriptions/$user/topics').update({topic: true});
          });
        } else {
          database.ref('subscriptions/$user/topics').update({topic: true});
        }
      });
    }).catchError((onError) => showErrorDialog(context, onError));
  }

  void unSubscribeFromTopic(String topic) {
    FirebaseMessaging.instance.unsubscribeFromTopic(topic).then((value) {
      database.ref('subscriptions/$user/topics').update({topic: false});
    }).catchError((onError) => showErrorDialog(context, onError));
  }

  void showMessageDialog(Map lastData) {
    String topic = lastData['topic'] ?? '';
    String message = lastData['message'] ?? '';
    String date = lastData['date'] ?? '';

    showDialog(
        context: context,
        builder: (ctx) => ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 2),
              child: AlertDialog(
                  title: Text('Nowe powiadomienie'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Column(
                          children: [
                            Text(topic, style: normalBlue,),
                            SizedBox(height: space,),
                            Text(message, style: normal,),
                            SizedBox(height: space,),
                            Text(date, style: normalGrey,)
                          ],
                        )
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {Navigator.of(ctx).pop(); },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: const Text('Ok'),
                      ),
                    ),
                  ]),
            ));
  }

  
}
