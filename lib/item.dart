import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class Item{
  String key;
  String name;
  bool subscribable;

  Item(this.key, this.name, this.subscribable);

  factory Item.fromJson(String itemKey, dynamic json){
    String key = itemKey;
    String name = json['name'];
    bool subscribable = json['subscribable'];

    return Item(key, name, subscribable);
  }
}

String createTopic(String name, List<Item> itemsPath) {
  String topic = '';
  itemsPath.skip(1).forEach((e) {
    topic += '${e.name}_';
  });
  topic += name;

  topic = topic.replaceAll(' ', '%');

  return topic;
}

