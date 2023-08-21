import 'dart:typed_data';

import 'package:get/get.dart';

class PasteboardItem {
  static var selectedItems = RxList<PasteboardItem>();
  var selected = RxBool(false);
  int? id;
  String? text;
  Uint8List? image;
  int type = 0;
  String? sha256;

  //创建时间
  int? createTime;
  String? path;

  PasteboardItem(this.type,
      {this.text, this.image, this.sha256, this.createTime}) {
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
    type = map['type'];
    text = map['text'];
    image = map['image'];
    sha256 = map['sha256'];
    createTime = map['create_time'];
    path = map['path'];
    _init();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'image': image,
      'sha256': sha256,
      'create_time': createTime,
      'path': path,
    };
  }
}
