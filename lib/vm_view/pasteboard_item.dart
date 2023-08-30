import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

enum PasteboardItemType {
  text,
  html,
  image,
  file,
}
class PasteboardItem {
  FocusNode? focusNode;
  static Rx<PasteboardItem?> current = Rx(null);
  static var selectedItems = RxList<PasteboardItem>();
  var selected = RxBool(false);
  int? id;
  String? text;
  Uint8List? image;
  PasteboardItemType type= PasteboardItemType.text;
  String? sha256;

  //创建时间
  int? createTime;
  String? path;

  String? html;

  PasteboardItem(this.type,
      {this.text, this.image,this.html, this.sha256, this.createTime}) {
    _init();
  }

  void _init() {
    selected.listenAndPump((p0) {
      if (p0) {
        selectedItems.add(this);
      } else {
        selectedItems.remove(this);
      }
    });
  }

  PasteboardItem.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    type = PasteboardItemType.values.where(
            (element) => element.toString() == map['type']
    ).firstOrNull??PasteboardItemType.text;
    text = map['text'];
    image = map['image'];
    sha256 = map['sha256'];
    createTime = map['create_time'];
    path = map['path'];
    html = map['html'];
    _init();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'text': text,
      'image': image,
      'sha256': sha256,
      'create_time': createTime,
      'path': path,
    };
  }
}
