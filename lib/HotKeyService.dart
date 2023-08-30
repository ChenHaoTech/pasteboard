// ignore_for_file: non_constant_identifier_names

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/single_service.dart';
import 'package:flutter_pasteboard/utils/PasteUtils.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:window_manager/window_manager.dart';

class HotKeySerice extends GetxController {
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();
  @override
  void onInit() {
    super.onInit();
    // space_test();
    bindRouteHotKey();
    bindGlobalKey();
  }
  final HotKey _hotKey = HotKey(
    KeyCode.keyV,
    modifiers: [
      KeyModifier.meta,
      KeyModifier.alt,
      KeyModifier.control,
      KeyModifier.shift
    ],
    // Set hotkey scope (default is HotKeyScope.system)
    scope: HotKeyScope.system, // Set as inapp-wide hotkey.
  );

  void bindGlobalKey(){
    hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        await windowService.requestWindowShow();
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          fixHotKeyBug();
        });
      },
    );
    hotKeyManager.register(
        HotKey(
          KeyCode.keyV,
          modifiers: [
            KeyModifier.control,
            KeyModifier.shift,
          ],
          // Set hotkey scope (default is HotKeyScope.system)
          scope: HotKeyScope.system, // Set as inapp-wide hotkey.
        ),

      keyDownHandler: (hotKey) async {
        var item = clipboardVM.pasteboardItemsWithSearchKey[1];
        var task = PasteUtils.doCopy(item);
        await task;
        await PasteUtils.doPaste(item);
      },
    );
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
      Get.toNamed("markdown");
    });
    // cmd + p togglePin
    hotKeyManager.register(
        HotKey(KeyCode.keyP,
            modifiers: [KeyModifier.meta],
            scope: HotKeyScope.inapp), keyDownHandler: (hotKey) {
      Get.find<WindowService>().alwaysOnTop.toggle();
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


  void fixHotKeyBug(){
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // ignore: invalid_use_of_visible_for_testing_member
      RawKeyboard.instance.clearKeysPressed();
    });
  }
}
