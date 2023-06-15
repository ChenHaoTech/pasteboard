import 'dart:typed_data';

class PasteboardItem {
  int? id;
  String? text;
  Uint8List? image;
  int type = 0;
  String? sha256;
  //创建时间
  int? createTime;
  String? path;

  PasteboardItem(this.type,
      {this.text, this.image, this.sha256, this.createTime});

  PasteboardItem.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    type = map['type'];
    text = map['text'];
    image = map['image'];
    sha256 = map['sha256'];
    createTime = map['create_time'];
    path = map['path'];
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
