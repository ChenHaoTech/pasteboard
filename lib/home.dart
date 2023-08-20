import 'dart:io';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/MetaIntent.dart';
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

import 'vm_view/pasteboard_item_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with ClipboardListener, WindowListener {
  List<PasteboardItem> pasteboardItems = [];
  ClipboardWatcher clipboardWatcher = ClipboardWatcher.instance;
  late ScrollController _scrollController;

  final HotKey _hotKey = HotKey(
    KeyCode.keyV,
    modifiers: [KeyModifier.meta, KeyModifier.alt, KeyModifier.control],
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

    DatabaseHelper().queryAll().then((value) {
      setState(() {
        pasteboardItems.addAll(value);
      });
    });
  }

  void bindHotKey() {
    hotKeyManager.unregisterAll();
    hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        windowManager.showWithoutActive();
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
        windowManager.setPosition(position, animate: false);
        windowManager.focus();
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        setState(() {});
      },
      // Only works on macOS.
      keyUpHandler: (hotKey) {},
    );
    hotKeyManager.register(_escKey, keyDownHandler: (hotKey) {
      windowManager.hide();
    });
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

  var searchKey = RxString("");

  @override
  Widget build(BuildContext context) {
    var scrollView = CustomScrollView(
      controller: _scrollController,
      slivers: [
        buildSearchEditor(),
        buildPasteboardHis(),
      ],
    );
    return Scaffold(
      // body: buildMetaIntentWidget(scrollView),
      body: KeyboardBindingWidget(
        onMetaAction: (MetaIntent intent, BuildContext context) {
          logger.i("MetaIntentWidget, dig: ${intent.digKey} ");
          PasteUtils.doAsyncPaste(pasteboardItems[intent.digKey]);
          windowManager.hide();
        },
        metaIntentSet: {meta_1: MetaIntent(1)},
        child: scrollView,
      ),
    );
  }

  MetaIntentWidget buildMetaIntentWidget(CustomScrollView scrollView) {
    return MetaIntentWidget(
      onAction: (int digKey) {
        // EasyLoading.showSuccess('loading...');
        PasteUtils.doAsyncPaste(pasteboardItems[digKey]);
        logger.i("MetaIntentWidget, dig: ${digKey} ");
        windowManager.hide();
      },
      child: scrollView,
    );
  }

  SliverToBoxAdapter buildPasteboardHis() {
    return SliverToBoxAdapter(
      child: Obx(
        () {
          var sk = searchKey.value;
          var data = pasteboardItems
              .where((element) => element.text?.contains(sk) ?? false)
              .toList();
          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return PasteboardItemView(
                  index: index,
                  item: data[index],
                  onTap: () async {
                    await PasteUtils.doAsyncPaste(pasteboardItems[index]);
                    windowManager.hide();
                  },
                );
              });
        },
      ),
    );
  }

  SliverToBoxAdapter buildSearchEditor() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6, right: 16),
        child: Row(
          children: [
            // 输入框, 搜索关键字
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 16),
                ),
                onChanged: (value) {
                  //todo 做个 debounce?
                  searchKey.value = value;
                },
              ),
            ),
          ],
        ),
      ),
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
    for (int i = 0; i < pasteboardItems.length; i++) {
      PasteboardItem item = pasteboardItems[i];
      if (item.sha256 == targetItem!.sha256) {
        targetItem = item;
        pasteboardItems.removeAt(i);
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
    pasteboardItems.insert(0, targetItem);
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
  void onWindowBlur() {
    //hide window when blur
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
    var future = Future.delayed(const Duration(milliseconds: 40), () async {
      // 1.1 Simulate key down
      await keyPressSimulator.simulateCtrlVKeyPress();
      // print(2);
    });
    return future;
  }
}
