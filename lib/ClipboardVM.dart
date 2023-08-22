import 'dart:io';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter_pasteboard/utils/logger.dart';
import 'package:flutter_pasteboard/utils/sha256_util.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

import 'database_helper.dart';

class ClipboardVM extends GetxController with ClipboardListener {
  final ClipboardWatcher clipboardWatcher = ClipboardWatcher.instance;
  final pasteboardItems = RxList<PasteboardItem>();
  final pasteboardItemsWithSearchKey = RxList<PasteboardItem>();
  final searchKey = RxString("");
  final alwaysOnTop = RxBool(false);
  final editMarkdownContext = RxString("");
  final markdownType = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    //todo  性能优化
    pasteboardItems.listen((p0) {
      pasteboardItemsWithSearchKey.clear();
      pasteboardItemsWithSearchKey.addAll(pasteboardItems.where(predict));
    });
    searchKey.listen((p0) {
      pasteboardItemsWithSearchKey.clear();
      pasteboardItemsWithSearchKey.addAll(pasteboardItems.where(predict));
    });
    DatabaseHelper.instance.query().then((value) {
      pasteboardItems.addAll(value);
    });
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  bool predict(PasteboardItem p0) {
    // 以后可以变得更复杂
    return p0.text?.contains(searchKey.value) ?? false;
  }
  @override
  void onClipboardChanged() async {
    PasteboardItem? targetItem;
    targetItem = await getTxtOrHtml();
    final image = await Pasteboard.image;
    if (image != null) {
      String sha256 = SHA256Util.calculateSHA256(image);
      targetItem = PasteboardItem(PasteboardItemType.image,
          image: image, sha256: sha256); //图片
    }
    // 如果 都没有, 就获取剪切板失败
    if (targetItem == null) {
      return;
    }
    for (int i = 0; i < pasteboardItems.length; i++) {
      PasteboardItem item = pasteboardItems[i];
      if (item.sha256 == targetItem!.sha256) {
        targetItem = item;
        pasteboardItems.removeAt(i);
        break;
      }
    }
    targetItem!.createTime = DateTime.now().millisecondsSinceEpoch;
    if (targetItem.type == PasteboardItemType.image && targetItem.path == null) {
      targetItem = await saveImageToLocal(targetItem);
    }
    if (targetItem.id != null) {
      DatabaseHelper.instance.update(targetItem);
    } else {
      try {
        targetItem = await DatabaseHelper.instance.insert(targetItem);
      } catch (e) {
        logger.e(e);
        return;
      }
    }
    pasteboardItems.insert(0, targetItem);
  }

  Future<PasteboardItem?> getTxtOrHtml() async {
     RichClipboardData rData = await RichClipboard.getData();
     PasteboardItem? targetItem;
    // ClipboardData? newClipboardData =
    //     await Clipboard.getData(Clipboard.kTextPlain);
    if (rData.text != null && rData.text!.trim().isNotEmpty) {
      //这里可以做 一些插件
      String text = rData.text!.trim();
      String sha256 = SHA256Util.calculateSHA256ForText(text);
      targetItem = PasteboardItem(PasteboardItemType.text,
          text: text, sha256: sha256); // 文字
    } else if (rData.html != null && rData.html!.trim().isNotEmpty) {
      String html = rData.html!.trim();
      String sha256 = SHA256Util.calculateSHA256ForText(html);
      targetItem = PasteboardItem(PasteboardItemType.html,
          html: html, sha256: sha256); // html
    }
    // bmcheng
     if (markdownType.value) {
      editMarkdownContext.value += "\n${targetItem?.text}";
    }
    return targetItem;
  }
  Future<PasteboardItem> saveImageToLocal(PasteboardItem item) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final fileName = "${item.sha256}.png";
    final file = File('$path/$fileName');
    await file.writeAsBytes(item.image!);
    item.path = file.path;
    return item;
  }

  @override
  void dispose() {
    super.dispose();
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }
}
