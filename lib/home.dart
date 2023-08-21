import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/database_helper.dart';
import 'package:flutter_pasteboard/utils/logger.dart';
import 'package:flutter_pasteboard/utils/sha256_util.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
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

class _HomePageState extends State<HomePage>
    with ClipboardListener, WindowListener {
  ClipboardWatcher clipboardWatcher = ClipboardWatcher.instance;
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
  final HotKey _escKey = HotKey(
    KeyCode.escape,
    scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();

    bindHotKey();
    windowManager.addListener(this);
  }

  void bindHotKey() async {
    await hotKeyManager.unregisterAll();
    bind1_9();
    //cmd + f 聚焦搜索栏
    hotKeyManager.register(
      HotKey(
        KeyCode.keyF,
        modifiers: [KeyModifier.meta],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        _searchFsn.requestFocus();
      },
    );

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
    hotKeyManager.register(
      HotKey(
        KeyCode.keyP,
        modifiers: [KeyModifier.meta, KeyModifier.alt],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        togglePin();
      },
    );
    hotKeyManager.register(
      HotKey(
        KeyCode.keyC,
        modifiers: [KeyModifier.meta],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        var items = clipboardVM.pasteboardItemsWithSearchKey
            .where((p0) => p0.selected.value)
            .toList();
        await PasteUtils.doAsyncPasteMerge(items.reversed.toList());
        EasyLoading.showSuccess("copy success");
      },
    );
    // command + plus 调高透明度
    hotKeyManager.register(
      HotKey(
        KeyCode.equal,
        modifiers: [KeyModifier.meta],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        var opac = await windowManager.getOpacity();
        windowManager.setOpacity(opac + 0.1);
      },
    );
    // command + minus 调低透明度
    hotKeyManager.register(
      HotKey(
        KeyCode.minus,
        modifiers: [KeyModifier.meta],
        // Set hotkey scope (default is HotKeyScope.system)
        scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
      ),
      keyDownHandler: (hotKey) async {
        var opac = await windowManager.getOpacity();
        windowManager.setOpacity(opac - 0.1);
      },
    );
    // up + down 移动 光标焦点

    hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
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
        focusNodeMap[curFocusIdx]?.unfocus();
        curFocusIdx = -1;
        windowManager.focus();
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        _searchFsn.requestFocus();
        windowManager.setAlwaysOnTop(clipboardVM.alwaysOnTop.value);
      },
      // Only works on macOS.
      keyUpHandler: (hotKey) {},
    );
    hotKeyManager.register(_escKey, keyDownHandler: (hotKey) {
      var selectedItems = PasteboardItem.selectedItems;
      if (selectedItems.isNotEmpty) {
        //todo 还有 bug
        for (var value in selectedItems) {
          value.selected.value = false;
        }
        return;
      }
      if (clipboardVM.searchKey.isNotEmpty) {
        clipboardVM.searchKey.value = "";
        return;
      }
      if (clipboardVM.alwaysOnTop.value) {
        windowManager.blur();
      } else {
        hideWindow();
      }
    });
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
      // if (kDebugMode) {
      //   print(
      //     "RawKeyboard.instance.keysPressed: ${RawKeyboard.instance.keysPressed}");
      // }
      for (int i = 0; i < digitKey.length; i++) {
        if (RawKeyboard.instance.keysPressed.length == 2 &&
            event.isKeyPressed(digitKey[i].logicalKey) &&
            event.isMetaPressed) {
          var pasteboardItems = clipboardVM.pasteboardItemsWithSearchKey;
          if (pasteboardItems.length > i) {
            await windowManager.hide();
            await PasteUtils.doAsyncPaste(pasteboardItems[i]);
            return true;
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
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomScrollView(
      controller: _scrollController,
      slivers: [
        buildSearchEditor(),
        buildPasteboardHis(),
      ],
    );
    child = KeyboardBindingWidget<CustomIntent>(
      metaIntentSet: {
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const CustomIntent("up"),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const CustomIntent("down"),
      },
      onMetaAction: (CustomIntent intent, BuildContext context) {
        var lastFsn = focusNodeMap[curFocusIdx];
        switch (intent.key) {
          case "up":
            curFocusIdx = max(curFocusIdx - 1, 0);
          case "down":
            curFocusIdx = min(curFocusIdx + 1, focusNodeMap.length - 1);
        }
        var fsn = focusNodeMap[curFocusIdx];
        if (fsn == null) {
          lastFsn?.unfocus();
        } else {
          fsn.requestFocus();
        }

        // todo 跑快点的时候 会有问题, 滚动不准
        var curOffset = _scrollController.offset;
        // EasyLoading.showSuccess("${fsn?.rect.top}, curOffset: $curOffset");
        var fsnOffset = fsn?.rect.top ?? 0;
        // if (curOffset < fsnOffset) {
        //   // _scrollController.offset
        // }
        var diff = fsnOffset - (lastFsn?.rect.top ?? 0);
        ;
        var targetOffset = curFocusIdx == 0 ? 0.0 : curOffset + diff;
        _scrollController.animateTo(targetOffset,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      },
      child: child,
    );
    return Scaffold(
      // body: buildMetaIntentWidget(scrollView),
      // body: _test_buildKeyboardBindingWidget(scrollView),
      body: child,
    );
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

  var curFocusIdx = -1;
  var focusNodeMap = <int, FocusNode>{};

  Widget buildPasteboardItemView(int index, RxList<PasteboardItem> data) {
    var item = data[index];
    focusNodeMap.update(index, (value) => FocusNode(),
        ifAbsent: () => FocusNode());
    return Obx(() {
      var selected = item.selected;
      return PasteboardItemView(
        focusNode: focusNodeMap[index],
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
            await PasteUtils.doAsyncPaste(item);
            hideWindow();
          }
        },
      );
    });
  }

  final FocusNode _searchFsn = FocusNode();

  SliverToBoxAdapter buildSearchEditor() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6, right: 16),
        child: Row(
          children: [
            // 输入框, 搜索关键字
            Expanded(
              child: TextField(
                autofocus: true,
                focusNode: _searchFsn,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 16),
                ),
                onChanged: (value) {
                  //todo 做个 debounce?
                  clipboardVM.searchKey.value = value;
                  focusNodeMap[curFocusIdx]?.unfocus();
                  focusNodeMap.clear();
                  curFocusIdx = -1;
                },
              ),
            ),
            // buildCreateWindowBtn(),
            buildPinWindowBtn(),
          ],
        ),
      ),
    );
  }

  ElevatedButton buildPinWindowBtn() {
    return ElevatedButton(onPressed: () async {
      await togglePin();
    }, child: Obx(() {
      return Text((clipboardVM.alwaysOnTop.value) ? 'Unpin' : 'Pin');
    }));
  }

  Future<void> togglePin() async {
    await windowManager.setAlwaysOnTop(!clipboardVM.alwaysOnTop.value);
    clipboardVM.alwaysOnTop.value = !clipboardVM.alwaysOnTop.value;
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
  void onClipboardChanged() async {
    PasteboardItem? targetItem;
    ClipboardData? newClipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (newClipboardData?.text != null &&
        newClipboardData!.text!.trim().isNotEmpty) {
      String text = newClipboardData.text!.trim();
      String sha256 = SHA256Util.calculateSHA256ForText(text);
      targetItem = PasteboardItem(0, text: text, sha256: sha256); // 文字
    }
    final image = await Pasteboard.image;
    if (image != null) {
      String sha256 = SHA256Util.calculateSHA256(image);
      targetItem = PasteboardItem(1, image: image, sha256: sha256); //图片
    }
    if (targetItem == null) {
      return;
    }
    for (int i = 0; i < clipboardVM.pasteboardItems.length; i++) {
      PasteboardItem item = clipboardVM.pasteboardItems[i];
      if (item.sha256 == targetItem!.sha256) {
        targetItem = item;
        clipboardVM.pasteboardItems.removeAt(i);
        break;
      }
    }
    targetItem!.createTime = DateTime.now().millisecondsSinceEpoch;
    if (targetItem.type == 1 && targetItem.path == null) {
      targetItem = await saveImageToLocal(targetItem);
    }
    if (targetItem.id != null) {
      DatabaseHelper().update(targetItem);
    } else {
      try {
        targetItem = await DatabaseHelper().insert(targetItem);
      } catch (e) {
        logger.e(e);
        return;
      }
    }
    clipboardVM.pasteboardItems.insert(0, targetItem);
  }

  Future<PasteboardItem> saveImageToLocal(PasteboardItem item) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final fileName = "${item.sha256}.png";
    final file = File('$path/$fileName');
    await file.writeAsBytes(item.image!);
    item.path = file.path;
    logger.i("save image to local success");
    return item;
  }

  @override
  void onWindowBlur() async {
    if (!clipboardVM.alwaysOnTop.value) {
      //hide window when blur
      hideWindow();
    }
    // 100 ms 后清楚键盘, 这个 bug 官方还没解决
    // [\[Web\]\[Windows\]: RawKeyboard listener not working as intended on web (Ctrl + D opens bookmark) · Issue #91603 · flutter/flutter --- \[Web\]\[Windows\]：RawKeyboard 侦听器无法在 Web 上按预期工作（Ctrl + D 打开书签）·问题 #91603·flutter/flutter](https://github.com/flutter/flutter/issues/91603)
    await Future.delayed(100.milliseconds);
    // ignore: invalid_use_of_visible_for_testing_member
    RawKeyboard.instance.clearKeysPressed();
  }

  void hideWindow() {
    windowManager.hide();
  }

  @override
  void onWindowFocus() {
    // print('onWindowFocus');
  }
}

class PasteUtils {
  static Future<void> doAsyncPaste(PasteboardItem item) async {
    if (item.type == 0) {
      Clipboard.setData(ClipboardData(text: item.text!));
    } else if (item.type == 1) {
      await Pasteboard.writeFiles([item.path!]);
    }
    // ignore: deprecated_member_use
    return await keyPressSimulator.simulateCtrlVKeyPress();
  }

  static Future<void> doAsyncPasteMerge(List<PasteboardItem> items) async {
    if (items.isEmpty) {
      EasyLoading.showInfo("No selected content");
      return;
    }
    var resStr = "";
    for (var item in items) {
      if (item.type == 0) {
        // todo 支持更多样的文本格式
        resStr += "\n${item.text!}";
      } else if (item.type == 1) {
        EasyLoading.showSuccess("type: ${item.type},🚧WIP");
      }
    }
    Clipboard.setData(ClipboardData(text: resStr));
    // ignore: deprecated_member_use
    return await keyPressSimulator.simulateCtrlVKeyPress();
  }
}
