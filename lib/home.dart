// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/utils/PasteUtils.dart';
import 'package:flutter_pasteboard/utils/function.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'obsolete/MetaIntent.dart';
import 'single_service.dart';
import 'vm_view/pasteboard_item_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(() {
      updateStatusBarHint.value++;
    });
    _scrollController = ScrollController();
    windowService.autoFocusOnWindowShow = _searchFsn;
    bindHotKey();
    windowManager.addListener(this);

    showSecondPanel.listen((p0) {
      if (p0) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (secondField.context?.mounted != true) return;
          secondField.requestFocus();
        });
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (secondField.context?.mounted != true) return;
          secondField.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
        });
      }
    });
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
  }

  Future<void> onCopyKeyDown() async {
    var items = clipboardVM.pasteboardItemsWithSearchKey.where((p0) => p0.selected.value).toList();
    var list = items.reversed.toList();

    if (list.isEmpty) {
      list = PasteboardItem.current.value?.map((val) => [val]) ?? [];
    }
    // clearKeyPress();
    PasteUtils.doMultiCopy(list);
    EasyLoading.showSuccess("copy success,count:${list.length}");
    return;
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
        if (pressed.length == 2 && event.isKeyPressed(digitKey[i].logicalKey)) {
          if (pasteboardItems.length > i) {
            var item = pasteboardItems[i];
            if (event.isMetaPressed) {
              await _paste(item);
            } else if (event.isShiftPressed) {
              item.focusNode?.requestFocus();
            }
            return;
          }
        }
      }
    };
  }

  // 定义一个 isMetaPressed get
  bool get isMetaPressed {
    return RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaRight);
  }

  bool get isShiftPresssd {
    return RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);
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
    windowService.autoFocusOnWindowShow = null;
  }

  final FocusNode _keyBoardWidgetFsn = FocusNode().apply((it) {
    it.debugLabel = "keyBoardWidgetFsn";
  });

  @override
  Widget build(BuildContext context) {
    Widget child = CustomScrollView(
      controller: _scrollController,
      slivers: [
        buildPasteboardHis(),
      ],
    );
    child = MyFocusableActionWidget<CustomIntentWithAction>(
      // KeyEventResult Function(FocusNode node, RawKeyEvent event)
      onRawKeyEvent: (FocusNode node, RawKeyEvent event) {
        updateStatusBarHint.value++;
        return KeyEventResult.ignored;
      },
      focusNode: _keyBoardWidgetFsn,
      onFocusChange: (hasFocus, kw) {
        updateStatusBarHint.value++;
        // if (!hasFocus) {
        //   kw.enableIntent.value = false;
        // }
      },
      intentSet: metaIntentSet,
      onAction: (CustomIntentWithAction intent, BuildContext context) async {
        await intent.func(context, intent);
        // clearKeyPress();
      },
      child: child,
    );
    return Scaffold(
      appBar: AppBar(
        title: buildSearchEditor(),
        actions: [
          buildPinWindowBtn(),
          // buildCreateWindowBtn(),
        ],
      ),
      // body: buildMetaIntentWidget(scrollView),
      // body: _test_buildKeyboardBindingWidget(scrollView),
      body: Stack(
        children: [_buildSecondPanel(child), Positioned(bottom: 10, child: SizedBox(height: 20, child: buildStatusBar()))],
      ),
    ).easyShortcuts(
      intentSet: {
        LogicalKeySet(KeyCode.keyD.logicalKey, LogicalKeyboardKey.meta, LogicalKeyboardKey.shift):
            CustomIntentWithAction("meta_shift_d", (context, intent) async {
          showSecondPanel.value = !showSecondPanel.value;
        }),
        LogicalKeySet(KeyCode.keyF.logicalKey, LogicalKeyboardKey.meta): CustomIntentWithAction("meta_f", (context, intent) async {
          _searchFsn.requestFocus();
        }),
        LogicalKeySet(KeyCode.escape.logicalKey): CustomIntentWithAction("esc", (context, intent) async {
          onEscKeyDown();
        })
      },
    );
  }

  var showSecondPanel = RxBool(false);
  var secondField = FocusNode().apply((it) {
    it.debugLabel = "second panel";
    it.skipTraversal = true;
  });

  Widget _buildSecondPanel(Widget child) {
    return Obx(() {
      if (PasteboardItem.selectedItems.isEmpty && !showSecondPanel.value) {
        return child;
      }
      var res = PasteboardItem.selectedItems.map((it) => it.text).join("\n");
      if (res.isEmpty) {
        res = PasteboardItem.current.value?.text ?? "";
      }
      var textField = TextField(
        autofocus: true,
        focusNode: secondField,
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
            child: textField.easyShortcuts(
              intentSet: {
                LogicalKeySet(KeyCode.escape.logicalKey): CustomIntentWithAction("esc", (context, intent) async {
                  var fsn = PasteboardItem.current.value?.focusNode;
                  if (fsn != null) {
                    fsn.requestFocus();
                  } else {
                    secondField.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
                  }
                }),
                LogicalKeySet(KeyCode.tab.logicalKey, LogicalKeyboardKey.shift): CustomIntentWithAction("shift_tab", (context, intent) async {
                  var fsn = PasteboardItem.current.value?.focusNode;
                  if (fsn != null) {
                    fsn.requestFocus();
                  } else {
                    secondField.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
                  }
                }),
              },
            ),
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
          var listView = ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return buildPasteboardItemView(index, data);
              });
          return listView.easyFocusTraversal();
        },
      ),
    );
  }

  Future<void> _paste(PasteboardItem item) async {
    // 没有 cmd 直接粘贴
    var task = PasteUtils.doCopy(item);
    await tryHideWindow(mustHide: true);
    await task;
    await PasteUtils.doPaste(item);
    if (windowService.alwaysOnTop.value) {
      windowManager.focus();
    }
  }

  Widget buildPasteboardItemView(int index, RxList<PasteboardItem> data) {
    var item = data[index];
    return Obx(() {
      var selected = item.selected;
      var focusNode = FocusNode(debugLabel: "item$index");
      return PasteboardItemView(
        index: index,
        item: item,
        focusNode: focusNode,
        // 选中了就深紫色 ,没有选中就正常色
        color: selected.value ? Colors.deepPurple.shade300 : Colors.deepPurple.shade50,
        onTap: () async {
          if (isMetaPressed) {
            item.selected.value = !(selected.value);
            focusNode.requestFocus();
          } else if (isShiftPresssd) {
            var items = PasteboardItem.selectedItems;
            items.forEach((e) {
              e.selected.value = false;
            });
            items.clear();
            focusNode.requestFocus();
            showSecondPanel.value = true;
          } else {
            // 没有 cmd 直接粘贴
            await _paste(item);
          }
        },
      ).easyShortcuts(intentSet: {
        LogicalKeySet(KeyCode.tab.logicalKey): CustomIntentWithAction("tab", (context, intent) async {
          if (showSecondPanel.value) {
            secondField.requestFocus();
          }
        }),
        LogicalKeySet(KeyCode.enter.logicalKey): CustomIntentWithAction("enter", (context, intent) async {
          _paste(item);
        }),
        LogicalKeySet(KeyCode.enter.logicalKey, LogicalKeyboardKey.shift): CustomIntentWithAction("shift_enter", (context, intent) async {
          focusNode.requestFocus();
          showSecondPanel.value = true;
        }),
      });
    });
  }

  final FocusNode _searchFsn = FocusNode().apply((it) {
    it.debugLabel = "search";
  });
  final TextEditingController _searchController = TextEditingController();

  Widget buildSearchEditor() {
    var textField = TextField(
      controller: _searchController,
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
    return textField.easyShortcuts(intentSet: {
      LogicalKeySet(KeyCode.arrowDown.logicalKey): CustomIntentWithAction("down", (context, intent) async {
        clipboardVM.pasteboardItemsWithSearchKey[0].focusNode?.requestFocus();
      }),
    });
  }

  IconButton buildPinWindowBtn() {
    return IconButton(
        iconSize: 16,
        focusNode: FocusNode().apply((e) => e.skipTraversal = true),
        onPressed: () async {
          Get.find<WindowService>().alwaysOnTop.toggle();
        },
        icon: Obx(() {
          var isTop = windowService.alwaysOnTop.value;
          return isTop ? const Icon(Icons.push_pin) : const Icon(Icons.push_pin_outlined);
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

  Future<void> tryHideWindow({bool mustHide = false}) async {
    if (!mustHide && windowService.alwaysOnTop.value) {
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
      updateStatusBarHint.value;
      var keys = RawKeyboard.instance.keysPressed.map((e) => e.keyLabel).join(",");
      var focus = FocusManager.instance.primaryFocus;
      // print(
      //     "[focus change] focus:${focus} \n child:${focus?.children} \nancestors: ${focus?.ancestors}\n descendants: ${focus?.descendants} \n parent : ${focus?.parent}\n");
      return Container(
        height: 10,
        color: Get.theme.scaffoldBackgroundColor,
        child: Text("debug:${debugFocusChanges} $updateStatusBarHint, $keys ${focus?.context?.widget}, \ncur: ${PasteboardItem.current}"),
      );
    });
  }

  Map<LogicalKeySet, CustomIntentWithAction> get metaIntentSet {
    return {
      LogicalKeySet(KeyCode.keyC.logicalKey, LogicalKeyboardKey.meta): CustomIntentWithAction("meta_c", (context, intent) async {
        onCopyKeyDown();
      }),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): CustomIntentWithAction("up", (context, intent) async {
        var fsn = FocusScope.of(context).focusedChild;
        if (fsn == _searchFsn) return;
        fsn?.previousFocus();
      }),
      LogicalKeySet(LogicalKeyboardKey.arrowDown): CustomIntentWithAction("down", (context, intent) async {
        var fsn = FocusManager.instance.primaryFocus;
        fsn?.focusInDirection(TraversalDirection.down);
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
    if (windowService.alwaysOnTop.value) {
      windowManager.blur();
    } else {
      tryHideWindow();
    }
  }
}
