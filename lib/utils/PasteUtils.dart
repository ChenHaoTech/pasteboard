import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/HotKeyService.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

class PasteUtils {
  static Future<void> doPaste(PasteboardItem item) async {
    // ignore: deprecated_member_use
    await keyPressSimulator.simulateCtrlVKeyPress();
    Get.find<HotKeySerice>().fixHotKeyBug();
  }

  static Future<void> doCopy(PasteboardItem item) async {
    if (item.type == PasteboardItemType.text) {
      await Clipboard.setData(ClipboardData(text: item.text!));
    } else if (item.type == PasteboardItemType.html) {
      await RichClipboard.setData(
          RichClipboardData(html: item.html ?? "", text: item.text));
    } else if (item.type == PasteboardItemType.image) {
      await Pasteboard.writeFiles([item.path!]);
    }
  }

  static Future<bool> doAsyncPasteMerge(List<PasteboardItem> items) async {
    if (items.isEmpty) {
      await EasyLoading.showInfo("No selected content");
      return false;
    }
    doMultiCopy(items);
    // ignore: deprecated_member_use
    await keyPressSimulator.simulateCtrlVKeyPress();
    return true;
  }

  static doMultiCopy(List<PasteboardItem> items) async {
    var resStr = "";
    for (var item in items) {
      if (item.type == PasteboardItemType.text) {
        // todo 支持更多样的文本格式
        resStr += "\n${item.text!}";
      } else {
        EasyLoading.showSuccess("type: ${item.type},🚧WIP");
      }
    }
    await Clipboard.setData(ClipboardData(text: resStr));
  }
}
