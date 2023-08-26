import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxController {
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();

  @override
  void onInit() {
    super.onInit();
    // space_test();
  }

  Future<void> togglePin() async {
    await windowManager.setAlwaysOnTop(!clipboardVM.alwaysOnTop.value);
    clipboardVM.alwaysOnTop.value = !clipboardVM.alwaysOnTop.value;
  }

  /*试试 看  fn 等键的绑定? */
  @override
  void onClose() {}

  @override
  void onReady() {}
}
