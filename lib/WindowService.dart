import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxController {
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();
  final alwaysOnTop = RxBool(false);
  final windowHide = RxBool(false);
  FocusNode? autoFocusOnWindowShow;

  @override
  void onInit() {
    super.onInit();
    windowHide.listen((p0) {
      if(p0) {
        windowManager.hide();
      } else {
        requestWindowShow();
      }
    });
    // space_test();
    alwaysOnTop.listen((p0) async{
      windowManager.setAlwaysOnTop(p0);
      if (!p0 && await isFocus()) {
        windowHide.value = true;
      }
    });
  }

  Future<void> requestWindowShow({Function? needDoOnWindowFocus = null}) async {
    windowManager.show();
    await windowManager.focus();
    if (needDoOnWindowFocus != null) {
      needDoOnWindowFocus.call();
    }else{
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        autoFocusOnWindowShow?.requestFocus();
      });
    }
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
