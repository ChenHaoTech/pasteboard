import 'dart:typed_data';

class PasteboardItem {
  String? text;
  Uint8List? image;
  int type = 0;
  String? sha256;

  PasteboardItem(this.type, {this.text, this.image, this.sha256});
}
