// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/utils/PasteUtils.dart';
import 'package:flutter_pasteboard/utils/function.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'obsolete/MetaIntent.dart';
import 'vm_view/pasteboard_item_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  late ScrollController _scrollController;
  late ClipboardVM clipboardVM = Get.find<ClipboardVM>();

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    bindHotKey();
    windowManager.addListener(this);
  }

  void bindHotKey() async {
    // await hotKeyManager.unregisterAll();
    bind1_9();

    // todo only 测试环境
    hotKeyManager.register(
      HotKey(
        KeyCode.keyR,
        modifiers: [KeyModifier.meta, KeyModifier.alt],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        bindHotKey();
      },
    );
    // command + w 关闭窗口
    hotKeyManager.register(
      HotKey(
        KeyCode.keyW,
        modifiers: [KeyModifier.meta],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        tryHideWindow(mustHide: true);
      },
    );
    hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        await _requestWindowShow();
      },
    );
  }

  Future<void> onCopyKeyDown() async {
    var items = clipboardVM.pasteboardItemsWithSearchKey
        .where((p0) => p0.selected.value)
        .toList();
    var list = items.reversed.toList();

    if (list.isEmpty) {
      list = PasteboardItem.current?.map((val) => [val]) ?? [];
    }
    // clearKeyPress();
    PasteUtils.doMultiCopy(list);
    EasyLoading.showSuccess("copy success,count:${list.length}");
    return;
  }

  Future<void> _requestWindowShow() async {
    windowManager.show();
    Offset position = await computePosition();
    // screenRetriever.getAllDisplays().then((value) {
    //   for (var element in value) {
    //     print('id: ${element.id}');
    //     print('dx: ${element.visiblePosition!.dx}');
    //     print('dy: ${element.visiblePosition!.dy}');
    //     print('width: ${element.size.width}');
    //     print('height: ${element.size.height}');
    //   }
    // });
    if (!await windowManager.isVisible()) {
      windowManager.setPosition(position, animate: false);
    }
    await windowManager.focus();
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 30), curve: Curves.easeOut);
    _searchFsn.requestFocus();
    windowManager.setAlwaysOnTop(clipboardVM.alwaysOnTop.value);
  }

  Future<void> bind1_9() async {
    var digitKey = [
      KeyCode.digit1,
      KeyCode.digit2,
      KeyCode.digit3,
      KeyCode.digit4,
      KeyCode.digit5,
      KeyCode.digit6,
      KeyCode.digit7,
      KeyCode.digit8,
      KeyCode.digit9
    ];
    var hotKeyList = <HotKey>[];
    for (var value in digitKey) {
      hotKeyList.add(
        HotKey(
          value,
          modifiers: [KeyModifier.meta],
          scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
          identifier: "cmd+$value",
        ),
      );
    }
    hotKeyManager.onRawKeyEvent = (event) async {
      var pressed = RawKeyboard.instance.keysPressed;
      var pasteboardItems = clipboardVM.pasteboardItemsWithSearchKey;
      for (int i = 0; i < digitKey.length; i++) {
        if (pressed.length == 2 &&
            event.isKeyPressed(digitKey[i].logicalKey) &&
            event.isMetaPressed) {
          if (pasteboardItems.length > i) {
            var item = pasteboardItems[i];
            var task = PasteUtils.doCopy(item);
            await tryHideWindow(mustHide: true);
            await task;
            await PasteUtils.doPaste(item);
            if(clipboardVM.alwaysOnTop.value){
              windowManager.focus();
            }
            return;
          }
        }
      }
    };
  }

  // 定义一个 isMetaPressed get
  bool get isMetaPressed {
    return RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.metaLeft) ||
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaRight);
  }

  Future<Offset> computePosition() async {
    Offset position = await screenRetriever.getCursorScreenPoint();
    position = await (Offset position) async {
      await screenRetriever.getPrimaryDisplay().then((value) {
        if (position.dy > 0 && position.dy + 350 > value.size.height) {
          position = Offset(position.dx, value.size.height - 350);
        } else if (position.dy < 0 && position.dy + 350 > 0) {
          position = Offset(position.dx, -350);
        }

        if (position.dx > 0 && position.dx + 210 > value.size.width) {
          position = Offset(value.size.width - 210, position.dy);
        } else if (position.dx < 0 && position.dx + 210 > 0) {
          position = Offset(-210, position.dy);
        }
      });
      return position;
    }(position);
    return position;
  }

  @override
  void dispose() {
    super.dispose();
    clipboardWatcher.stop();
    hotKeyManager.onRawKeyEvent = null;
  }

  final FocusNode _keyBoardWidgetFsn = FocusNode();

  @override
  Widget build(BuildContext context) {
    Widget child = CustomScrollView(
      controller: _scrollController,
      slivers: [
        buildSearchEditor(),
        buildPasteboardHis(),
      ],
    );
    child = KeyboardBindingWidget<CustomIntentWithAction>(
      // KeyEventResult Function(FocusNode node, RawKeyEvent event)
      onRawKeyEvent: (FocusNode node, RawKeyEvent event) {
        updateStatusBarHint.value++;
        if (event.isMetaPressed && event.character != "") {
          // 很骚的解决方法
          Future.microtask(() => clearKeyPress());
        }
        // EasyLoading.showSuccess("status: ${event.runtimeType}, ${event.logicalKey}");
        // if (event is RawKeyDownEvent) {
        //
        // }
        return KeyEventResult.ignored;
      },
      focusNode: _keyBoardWidgetFsn,
      onFocusChange: (hasFocus, kw) {
        updateStatusBarHint.value++;
        // if (!hasFocus) {
        //   kw.enableIntent.value = false;
        // }
      },
      metaIntentSet: metaIntentSet,
      onMetaAction:
          (CustomIntentWithAction intent, BuildContext context) async {
        await intent.func(context, intent);
        // clearKeyPress();
      },
      child: Stack(
        children: [
          _buildSecondPanel(child),
          Positioned(
              bottom: 10, child: SizedBox(height: 20, child: buildStatusBar()))
        ],
      ),
    );
    return Scaffold(
      // body: buildMetaIntentWidget(scrollView),
      // body: _test_buildKeyboardBindingWidget(scrollView),
      body: child,
    );
  }

  Widget _buildSecondPanel(Widget child) {
    return Obx(() {
      if (PasteboardItem.selectedItems.isEmpty) {
        return child;
      }
      var res = PasteboardItem.selectedItems.map((it) => it.text).join("\n");
      var textField = TextField(
        readOnly: true,
        focusNode: FocusNode().apply((it) {
          it.skipTraversal = true;
        }),
        controller: TextEditingController(text: res),
        decoration: const InputDecoration(border: InputBorder.none),
        maxLines: null,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) {},
      );
      // coloun
      return Row(
        children: [
          Flexible(
            flex: 1,
            child: child,
          ),
          Flexible(
            flex: 1,
            child: textField,
          ),
        ],
      );
    });
  }

  SliverToBoxAdapter buildPasteboardHis() {
    return SliverToBoxAdapter(
      child: Obx(
        () {
          var data = clipboardVM.pasteboardItemsWithSearchKey;
          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return buildPasteboardItemView(index, data);
              });
        },
      ),
    );
  }

  Widget buildPasteboardItemView(int index, RxList<PasteboardItem> data) {
    var item = data[index];
    return Obx(() {
      var selected = item.selected;
      return PasteboardItemView(
        index: index,
        item: item,
        // 选中了就深紫色 ,没有选中就正常色
        color: selected.value
            ? Colors.deepPurple.shade300
            : Colors.deepPurple.shade50,
        onTap: () async {
          if (isMetaPressed) {
            item.selected.value = !(selected.value);
          } else {
            // 没有 cmd 直接粘贴
            var task = PasteUtils.doCopy(item);
            await tryHideWindow(mustHide: true);
            await task;
            await PasteUtils.doPaste(item);
            if(clipboardVM.alwaysOnTop.value){
              windowManager.focus();
            }
          }
        },
      );
    });
  }

  final FocusNode _searchFsn = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  SliverToBoxAdapter buildSearchEditor() {
    var textField = TextField(
      controller: _searchController,
      autofocus: true,
      onTap: () {
        _searchFsn.requestFocus();
      },
      // onTapOutside: (event) {
      //   // _keyBoardWidgetFsn.requestFocus();
      // },
      focusNode: _searchFsn.apply((it) {
        it.skipTraversal = true;
      }),
      decoration: const InputDecoration(
        hintText: 'search',
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(left: 9),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        //todo 做个 debounce?
        clipboardVM.searchKey.value = value;
        // curFocusIdx = 0;
      },
    );
    var container = Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          // 输入框, 搜索关键字
          Expanded(
            child: FocusableActionDetector(
              child: textField,
            ),
          ),
          // buildCreateWindowBtn(),
          buildPinWindowBtn(),
        ],
      ),
    );
    return SliverToBoxAdapter(
      child: container,
    );
  }

  IconButton buildPinWindowBtn() {
    return IconButton(
        iconSize: 16,
        focusNode: FocusNode().apply((e) => e.skipTraversal = true),
        onPressed: () async {
          Get.find<WindowService>().togglePin();
        },
        icon: Obx(() {
          var isTop = clipboardVM.alwaysOnTop.value;
          return isTop
              ? const Icon(Icons.push_pin)
              : const Icon(Icons.push_pin_outlined);
        }));
  }

  ElevatedButton buildCreateWindowBtn() {
    return ElevatedButton(
      onPressed: () async {
        final window = await DesktopMultiWindow.createWindow(jsonEncode({
          'args1': 'Sub window',
          'args2': 100,
          'args3': true,
          'business': 'business_test',
        }));
        window
          ..setFrame(const Offset(0, 0) & const Size(1280, 720))
          ..center()
          ..setTitle('Another window')
          ..resizable(false)
          ..show();
      },
      child: const Text('Create a new World!'),
    );
  }

  @override
  void onWindowBlur() async {
    tryHideWindow();
    // curFocusIdx = 0;
    // 100 ms 后清楚键盘, 这个 bug 官方还没解决
    // [\[Web\]\[Windows\]: RawKeyboard listener not working as intended on web (Ctrl + D opens bookmark) · Issue #91603 · flutter/flutter --- \[Web\]\[Windows\]：RawKeyboard 侦听器无法在 Web 上按预期工作（Ctrl + D 打开书签）·问题 #91603·flutter/flutter](https://github.com/flutter/flutter/issues/91603)
    // await Future.delayed(30.milliseconds);
    //todo 只清理 合适的 可能得写 window、mac 插件
    // /Users/apple/Work/dev/flutter/packages/flutter/lib/src/services/system_channels.dart:284
    // static const BasicMessageChannel<Object?> keyEvent = BasicMessageChannel<Object?>(
    //       'flutter/keyevent',
    //       JSONMessageCodec(),
    //   );
    // clearKeyPress();
  }

  void clearKeyPress() {
    print("hint clearKeyPress");
    RawKeyboard.instance.clearKeysPressed();
    // // ignore: invalid_use_of_visible_for_testing_member
    // HardwareKeyboard.instance.clearState();
    // // ignore: invalid_use_of_visible_for_testing_member
    // ServicesBinding.instance.keyEventManager.clearState();
  }

  Future<void> tryHideWindow({bool mustHide = false}) async {
    if (!mustHide && clipboardVM.alwaysOnTop.value) {
      await windowManager.blur();
    } else {
      await windowManager.hide();
    }
  }

  @override
  void onWindowFocus() {
    // print('onWindowFocus');
  }

  var updateStatusBarHint = RxInt(0);

  Widget buildStatusBar() {
    return Obx(() {
      var hint = updateStatusBarHint.value;
      var keys =
          RawKeyboard.instance.keysPressed.map((e) => e.keyLabel).join(",");
      return Container(
        height: 10,
        color: Get.theme.scaffoldBackgroundColor,
        child: Text(
          "$keys,${FocusScope.of(context).focusedChild?.context?.widget}",
        ),
      );
    });
  }

  Map<LogicalKeySet, CustomIntentWithAction> get metaIntentSet {
    return {
      LogicalKeySet(LogicalKeyboardKey.arrowUp):
          CustomIntentWithAction("up", (context, intent) async {
        var fsn = FocusScope.of(context).focusedChild;
        fsn?.previousFocus();
      }),
      LogicalKeySet(LogicalKeyboardKey.arrowDown):
          CustomIntentWithAction("down", (context, intent) async {
        var fsn = FocusScope.of(context).focusedChild;
        fsn?.nextFocus();
      }),
      LogicalKeySet(KeyCode.keyF.logicalKey, LogicalKeyboardKey.meta):
          CustomIntentWithAction("meta_f", (context, intent) async {
        _searchFsn.requestFocus();
      }),
      LogicalKeySet(KeyCode.keyC.logicalKey, LogicalKeyboardKey.meta):
          CustomIntentWithAction("meta_c", (context, intent) async {
        onCopyKeyDown();
      }),
      LogicalKeySet(KeyCode.escape.logicalKey):
          CustomIntentWithAction("esc", (context, intent) async {
        onEscKeyDown();
      }),
    };
  }

  onEscKeyDown() {
    if (clipboardVM.searchKey.isNotEmpty) {
      clipboardVM.searchKey.value = "";
      _searchController.clear();
      EasyLoading.showSuccess("clear search key");
      return;
    }
    var selectedItems = PasteboardItem.selectedItems;
    if (selectedItems.isNotEmpty) {
      if (selectedItems.length == 1) {
        for (var value in selectedItems.toList()) {
          value.selected.value = false;
        }
      } else {
        Get.defaultDialog(
          content: const Text("clear all selected?"),
          confirm: TextButton(
            autofocus: true,
            onPressed: () {
              Get.back(result: true);
              for (var value in selectedItems.toList()) {
                value.selected.value = false;
              }
              // 关闭弹窗
              EasyLoading.showSuccess("clear all selected");
            },
            child: const Text("confirm"),
          ),
        );
      }
      return;
    }
    if (clipboardVM.alwaysOnTop.value) {
      windowManager.blur();
    } else {
      tryHideWindow();
    }
  }
}
