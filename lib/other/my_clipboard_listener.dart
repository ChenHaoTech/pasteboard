import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';

class MyClipboardListener extends ClipboardListener {
  @override
  void onClipboardChanged() async {
    ClipboardData? newClipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    print(newClipboardData?.text ?? "");
  }
}
