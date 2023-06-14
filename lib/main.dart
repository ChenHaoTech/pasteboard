import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pasteboard/database_helper.dart';
import 'package:flutter_pasteboard/pasteboard_item.dart';
import 'package:flutter_pasteboard/sha256_util.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:keypress_simulator/keypress_simulator.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'pasteboard_item_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(210, 350),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // await windowManager.show();
    // await windowManager.focus();
  });
  windowManager.hide();
  windowManager.setMovable(false);
  windowManager.setResizable(false);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with ClipboardListener, WindowListener {
  List<PasteboardItem> pasteboardItems = [];
  ClipboardWatcher clipboardWatcher = ClipboardWatcher.instance;
  late ScrollController _scrollController;

  final HotKey _hotKey = HotKey(
    KeyCode.keyV,
    modifiers: [KeyModifier.meta, KeyModifier.shift],
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

    hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        windowManager.showWithoutActive();
        Offset position = await screenRetriever.getCursorScreenPoint();
        // await screenRetriever.getPrimaryDisplay().then((value) {
        //   if (position.dy > 0 && position.dy + 350 > value.size.height) {
        //     position = Offset(position.dx, value.size.height - 350);
        //   } else if (position.dy < 0 && position.dy + 350 > 0) {
        //     position = Offset(position.dx, -350);
        //   }

        //   if (position.dx > 0 && position.dx + 210 > value.size.width) {
        //     position = Offset(value.size.width - 210, position.dy);
        //   } else if (position.dx < 0 && position.dx + 210 > 0) {
        //     position = Offset(-210, position.dy);
        //   }
        // });
        windowManager.setPosition(position, animate: true);
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
    windowManager.addListener(this);

    DatabaseHelper().queryAll().then((value) {
      setState(() {
        pasteboardItems.addAll(value);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding:
                  const EdgeInsets.only(left: 16, top: 6, bottom: 6, right: 16),
              child: Text("History",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  )
                  // style: TextStyle(color: Colors.grey.shade600),
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pasteboardItems.length,
                itemBuilder: (context, index) {
                  return PasteboardItemView(
                    index: index,
                    item: pasteboardItems[index],
                    onTap: () async {
                      PasteboardItem item = pasteboardItems[index];
                      if (item.type == 0) {
                        Clipboard.setData(ClipboardData(text: item.text!));
                      } else if (item.type == 1) {
                        Pasteboard.writeImage(item.image!);
                      }
                      windowManager.hide();
                      Future.delayed(const Duration(milliseconds: 40),
                          () async {
                        // 1.1 Simulate key down
                        await keyPressSimulator.simulateKeyPress(
                          key: LogicalKeyboardKey.keyV,
                          modifiers: [
                            ModifierKey.metaModifier,
                          ],
                        );
                        // print(2);
                      });
                    },
                  );
                }),
          ),
          _getDivider(),
          SliverToBoxAdapter(
            child: PasteboardItemView(
              type: 'button',
              item: PasteboardItem(0, text: "Settings"),
              onTap: () {},
            ),
          ),
          _getDivider(),
          SliverToBoxAdapter(
            child: PasteboardItemView(
              type: 'button',
              item: PasteboardItem(0, text: "Quit App"),
              onTap: () {
                //quit app
                windowManager.destroy();
                windowManager.close();
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 6),
          )
        ],
      ),
    );
  }

  SliverToBoxAdapter _getDivider() {
    return SliverToBoxAdapter(
        child: Column(
      children: [
        const SizedBox(
          height: 6,
        ),
        Container(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.expand(height: 1.0),
          child: const Divider(),
        ),
        const SizedBox(
          height: 6,
        ),
      ],
    ));
  }

  Color getColor(int index) {
    if (index % 2 == 0) {
      return Colors.deepPurple.shade50;
    } else {
      return Colors.deepPurple.shade50;
    }
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
      targetItem = PasteboardItem(0, text: text, sha256: sha256);
    }
    final image = await Pasteboard.image;
    if (image != null) {
      String sha256 = SHA256Util.calculateSHA256(image);
      targetItem = PasteboardItem(1, image: image, sha256: sha256);
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
    if (targetItem.id != null) {
      DatabaseHelper().update(targetItem);
    } else {
      try {
        targetItem = await DatabaseHelper().insert(targetItem);
      } catch (e) {
        print(e);
        return;
      }
    }
    pasteboardItems.insert(0, targetItem);
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
