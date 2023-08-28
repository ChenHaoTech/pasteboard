import 'package:flutter/cupertino.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxController {
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();
  final alwaysOnTop = RxBool(false);
  final windowHide = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    // space_test();
    alwaysOnTop.listen((p0) {
      windowManager.setAlwaysOnTop(p0);
    });
  }

  Future<void> requestWindowShow(Function? needDoOnWindowFocus) async {
    windowManager.show();
    await windowManager.focus();
    needDoOnWindowFocus?.call();
    windowManager.setAlwaysOnTop(alwaysOnTop.value);
  }

   Future<bool> isFocus() async {
     return await windowManager.isFocused();
  }
  ignoreKey(){
    print("windowManager.invokeMethod;");
    windowManager.invokeMethod("ignore_copy_key");
  }

  /*试试 看  fn 等键的绑定? */
  @override
  void onClose() {}

  @override
  void onReady() {}
}
