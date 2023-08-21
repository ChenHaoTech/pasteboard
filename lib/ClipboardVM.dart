import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';

import 'database_helper.dart';

class ClipboardVM extends GetxController {
  final pasteboardItems = RxList<PasteboardItem>();
  final pasteboardItemsWithSearchKey = RxList<PasteboardItem>();
  final searchKey = RxString("");
  final  alwaysOnTop = RxBool(false);

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
  }

  bool predict(PasteboardItem p0) {
    // 以后可以变得更复杂
    return p0.text?.contains(searchKey.value) ?? false;
  }
}
