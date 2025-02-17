import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxController {
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();
  final alwaysOnTop = RxBool(false);
  final windowHide = RxBool(false);
  FocusNode? autoFocusOnWindowShow;

  @override
  void onInit() async{
    super.onInit();
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(210 * 3, 350),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
    // windowManager.hide();
    // windowManager.show();
    windowManager.setMovable(true);
    windowManager.setResizable(true);
    windowManager.setVisibleOnAllWorkspaces(false);

    windowHide.listen((p0) {
      if(p0) {
        windowManager.hide();
      } else {
        requestWindowShow();
      }
    });
    // space_test();
    alwaysOnTop.listen((p0) async{
      if(p0){
        EasyLoading.showSuccess("📌PIN");
      }else{
        EasyLoading.showSuccess("UNPIN");
      }
      windowManager.setAlwaysOnTop(p0);
      if (!p0 && await isFocus()) {
        windowHide.value = true;
      }
    });
  }

  Future<void> requestWindowHide() async {
    await windowManager.hide();
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
