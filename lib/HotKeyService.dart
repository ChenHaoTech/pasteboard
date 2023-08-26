import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:keypress_simulator/keypress_simulator.dart';

class HotKeySerice extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // space_test();
    bindRouteHotKey();
  }

  /*试试 看  fn 等键的绑定? */

  void bindRouteHotKey() {
    // cmd+[ 后退
    hotKeyManager.register(
        HotKey(KeyCode.bracketLeft,
            modifiers: [KeyModifier.meta],
            scope: HotKeyScope.inapp), keyDownHandler: (hotKey) {
      Get.back();
    });
    // cmd+e 进入 markdown 界面
    hotKeyManager.register(
        HotKey(KeyCode.keyE,
            modifiers: [KeyModifier.meta],
            scope: HotKeyScope.inapp), keyDownHandler: (hotKey) {
      Get.find<ClipboardVM>().markdownType.value = true;
      Get.toNamed("markdown");
    });
  }

  void space_test() {
    hotKeyManager.register(HotKey(KeyCode.space), keyDownHandler: (hotKey) {
      print("fuck");
      KeyPressSimulator.instance
          .simulateKeyPress(key: KeyCode.space.logicalKey, keyDown: true);
    });
  }

  @override
  void onClose() {}

  @override
  void onReady() {}
}