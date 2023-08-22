import 'dart:convert';
import 'dart:io';
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
import 'package:rich_clipboard/rich_clipboard.dart';
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
  final HotKey _copy = HotKey(
    KeyCode.keyC,
    modifiers: [KeyModifier.meta],
    // Set hotkey scope (default is HotKeyScope.system)
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
    // command + c
    hotKeyManager.register(
      _copy,
      keyDownHandler: (hotKey) async {
        var items = clipboardVM.pasteboardItemsWithSearchKey
            .where((p0) => p0.selected.value)
            .toList();
        var list = items.reversed.toList();
        // if (list.isEmpty) {
        //   list = clipboardVM.pasteboardItemsWithSearchKey
        //       .getRange(curFocusIdx, curFocusIdx + 1)
        //       .toList();
        // }
        if (await PasteUtils.doAsyncPasteMerge(list)) {
          EasyLoading.showSuccess("copy success,count:${list.length}");
        }
        return;
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
    windowManager.focus();
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
      // if (kDebugMode) {
      //   print(
      //     "RawKeyboard.instance.keysPressed: ${RawKeyboard.instance.keysPressed}");
      // }
      var pressed = RawKeyboard.instance.keysPressed;
      for (int i = 0; i < digitKey.length; i++) {
        if (pressed.length == 2 &&
            event.isKeyPressed(digitKey[i].logicalKey) &&
            event.isMetaPressed) {
          var pasteboardItems = clipboardVM.pasteboardItemsWithSearchKey;
          if (pasteboardItems.length > i) {
            await tryHideWindow();
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
    hotKeyManager.unregister(_copy);
    hotKeyManager.onRawKeyEvent = null;
  }

  final FocusNode _KeyBoardWidgetFsn = FocusNode();

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
      focusNode: _KeyBoardWidgetFsn,
      metaIntentSet: {
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const CustomIntent("up"),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const CustomIntent("down"),
        LogicalKeySet(LogicalKeyboardKey.equal, LogicalKeyboardKey.meta):
            const CustomIntent("meta_="),
        LogicalKeySet(LogicalKeyboardKey.minus, LogicalKeyboardKey.meta):
            const CustomIntent("meta_-"),
        LogicalKeySet(KeyCode.comma.logicalKey, LogicalKeyboardKey.meta):
            const CustomIntent("meta_,"),
        LogicalKeySet(KeyCode.keyF.logicalKey, LogicalKeyboardKey.meta):
            const CustomIntent("meta_f"),
        LogicalKeySet(KeyCode.keyP.logicalKey, LogicalKeyboardKey.meta):
            const CustomIntent("meta_p"),
        LogicalKeySet(KeyCode.escape.logicalKey): const CustomIntent("esc"),
      },
      onMetaAction: (CustomIntent intent, BuildContext context) async {
        var fsn = FocusScope.of(context).focusedChild;
        var step = 20;
        switch (intent.key) {
          case "meta_p":
            togglePin();
            return;
          case "meta_,":
            EasyLoading.showInfo("🚧");
            return;
          case "meta_f":
            _searchFsn.requestFocus();
            return;
          case "up":
            fsn?.previousFocus();
            break;
          case "down":
            fsn?.nextFocus();
            break;
          case "meta_=":
            var size = await windowManager.getSize();
            size = Size(size.width + step, size.height + step);
            windowManager.setSize(size, animate: true);
            return;
          case "meta_-":
            var size = await windowManager.getSize();
            size = Size(size.width - step, size.height - step);
            windowManager.setSize(size, animate: true);
            return;
          case "esc":
            var selectedItems = PasteboardItem.selectedItems;
            if (selectedItems.isNotEmpty) {
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
                  ),);
              return;
            }
            if (clipboardVM.searchKey.isNotEmpty) {
              clipboardVM.searchKey.value = "";
              EasyLoading.showSuccess("clear search key");
              return;
            }
            if (clipboardVM.alwaysOnTop.value) {
              windowManager.blur();
            } else {
              tryHideWindow();
            }
            return;
          default:
            EasyLoading.showSuccess("unknow: ${intent.key}");
            return;
        }
      },
      child: _buildSecondPanel(child),
    );
    return Scaffold(
      // body: buildMetaIntentWidget(scrollView),
      // body: _test_buildKeyboardBindingWidget(scrollView),
      body: child,
    );
  }

  Widget _buildSecondPanel(Widget child) {
    return Obx((){
      if(PasteboardItem.selectedItems.isEmpty){
        return child;
      }
      var res= PasteboardItem.selectedItems.map((it) => it.text).join("\n");
      var textField= TextField(
        readOnly: true,
        controller: TextEditingController(text: res),
        decoration: const InputDecoration(border: InputBorder. none),
        maxLines: null,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) {

        },
      );
      // coloun
      return Row(
        children: [
          Flexible(flex:1 ,child: child,),
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
            await tryHideWindow();
            PasteUtils.doAsyncPaste(item);
          }
        },
      );
    });
  }

  final FocusNode _searchFsn = FocusNode();

  SliverToBoxAdapter buildSearchEditor() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          children: [
            // 输入框, 搜索关键字
            Expanded(
              child: TextField(
                autofocus: true,
                focusNode: _searchFsn,
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
    RichClipboardData rData = await RichClipboard.getData();
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
      DatabaseHelper.instance.update(targetItem);
    } else {
      try {
        targetItem = await DatabaseHelper.instance.insert(targetItem);
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
    tryHideWindow();
    // curFocusIdx = 0;
    // 100 ms 后清楚键盘, 这个 bug 官方还没解决
    // [\[Web\]\[Windows\]: RawKeyboard listener not working as intended on web (Ctrl + D opens bookmark) · Issue #91603 · flutter/flutter --- \[Web\]\[Windows\]：RawKeyboard 侦听器无法在 Web 上按预期工作（Ctrl + D 打开书签）·问题 #91603·flutter/flutter](https://github.com/flutter/flutter/issues/91603)
  }

  Future<void> tryHideWindow({bool mustHide = false}) async {
    if (!mustHide && clipboardVM.alwaysOnTop.value) {
      await windowManager.blur();
      // await Future.delayed(100.milliseconds);
      //todo 只清理 合适的 可能得写 window、mac 插件
      // /Users/apple/Work/dev/flutter/packages/flutter/lib/src/services/system_channels.dart:284
      // static const BasicMessageChannel<Object?> keyEvent = BasicMessageChannel<Object?>(
      //       'flutter/keyevent',
      //       JSONMessageCodec(),
      //   );
      // ignore: invalid_use_of_visible_for_testing_member
      RawKeyboard.instance.clearKeysPressed();
      return;
    }
    return await windowManager.hide();
  }

  @override
  void onWindowFocus() {
    // print('onWindowFocus');
  }
}

class PasteUtils {
  static Future<void> doAsyncPaste(PasteboardItem item) async {
    if (item.type == PasteboardItemType.text) {
      Clipboard.setData(ClipboardData(text: item.text!));
    } else if (item.type == PasteboardItemType.html) {
      RichClipboard.setData(RichClipboardData(text: item.html!));
    } else if (item.type == PasteboardItemType.image) {
      await Pasteboard.writeFiles([item.path!]);
    }
    // ignore: deprecated_member_use
    return await keyPressSimulator.simulateCtrlVKeyPress();
  }

  static Future<bool> doAsyncPasteMerge(List<PasteboardItem> items) async {
    if (items.isEmpty) {
      await EasyLoading.showInfo("No selected content");
      return false;
    }
    var resStr = "";
    for (var item in items) {
      if (item.type == PasteboardItemType.text) {
        // todo 支持更多样的文本格式
        resStr += "\n${item.text!}";
      } else if (item.type == 1) {
        EasyLoading.showSuccess("type: ${item.type},🚧WIP");
      }
    }
    Clipboard.setData(ClipboardData(text: resStr));
    // ignore: deprecated_member_use
    await keyPressSimulator.simulateCtrlVKeyPress();
    return true;
  }
}
