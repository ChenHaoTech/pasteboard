import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'package:audioplayers/audioplayers.dart';

loadAsset() async {
  await rootBundle.load('asserts/app_icon.png');
}

// todo 记得复用?
// 注意不要泄漏了
final audioPlayer = AudioPlayer();

openAudio() {
  var state = audioPlayer.state;
  // 播放时 按下暂停
  if (state == PlayerState.playing) {
    audioPlayer.pause();
    restore();
  } else if (state == PlayerState.stopped ||
      state == PlayerState.completed ||
      state == PlayerState.disposed) {
    //  已经停止的 直接播放
    audioPlayer.play(AssetSource('03-White-Noise-10min.mp3'));
    beginTime = DateTime.now();
    stopTime = beginTime.add(const Duration(minutes: 25));
    startTimer();
  } else if (state == PlayerState.paused) {
    // 暂停的继续播放
    audioPlayer.resume();
    beginTime = DateTime.now();
    startTimer();
  }
}

void restore() {
  timer.cancel();
  systemTray.setTitle("");
}

DateTime beginTime = DateTime.now();
DateTime stopTime = DateTime.now();
Timer timer = Timer(Duration.zero, () {});

String formatDuration(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds % 60;

  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = seconds.toString().padLeft(2, '0');

  return '$formattedMinutes:$formattedSeconds';
}

startTimer() {
  // 每隔一秒 刷新下 title
  timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    var diff = stopTime.difference(DateTime.now());
    // 和当前时间相比 过去了多久
    systemTray.setTitle(formatDuration(diff));

    if (diff.isNegative) {
      restore();
      showEndNotification();
    }
  });
}
void onMainArgsNewWindow(int windowId,String type,Map<String,String> args){
  WindowData.build(windowId, type, args);
  runApp(TomotoWin());
}


void showEndNotification() async {
  //todo 做一个封装
  final window = await DesktopMultiWindow.createWindow(jsonEncode({
    'args1': 'tomoto',
  }));
  window
    ..setFrame(const Offset(0, 0) & const Size(1280, 720))
    ..center()
    ..setTitle('Another window')
    ..resizable(false)
    ..show();
}
final SystemTray systemTray = SystemTray();

Future<void> initSystemTray() async {
  //todo 支持 windows
  if (Platform.isWindows) return;
  String path = 'assets/app_icon.png';

  final AppWindow appWindow = AppWindow();

  // We first init the systray menu
  await systemTray.initSystemTray(
    iconPath: path,
  );

  // create context menu
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
    MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
    MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
  ]);

  // set context menu
  await systemTray.setContextMenu(menu);

  // handle system tray event
  systemTray.registerSystemTrayEventHandler((eventName) {
    debugPrint("eventName: $eventName");
    if (eventName == kSystemTrayEventClick) {
      Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
    }
  });
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await tomotoBinding();
  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(210 * 3, 350),
  //   center: true,
  //   backgroundColor: Colors.transparent,
  //   skipTaskbar: true,
  //   titleBarStyle: TitleBarStyle.hidden,
  //   windowButtonVisibility: false,
  // );
  // await windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  // });
  // // windowManager.hide();
  // // windowManager.show();
  // windowManager.setMovable(true);
  // windowManager.setResizable(true);
  // windowManager.setVisibleOnAllWorkspaces(false);
  // Get.put(ClipboardVM());
  runApp(const TomotoWin());
  // configLoading();
}

Future<void> tomotoBinding() async {
  initSystemTray();
  // // Must add this line.

  var hotKey = HotKey(
    KeyCode.keyP,
    modifiers: [
      KeyModifier.control,
      // KeyModifier.shift,
      KeyModifier.alt,
      KeyModifier.meta,
    ],
    // Set hotkey scope (default is HotKeyScope.system)
    scope: HotKeyScope.system, // Set as inapp-wide hotkey.
  );
  await hotKeyManager.unregister(hotKey);
  await hotKeyManager.register(
      hotKey, keyDownHandler: (HotKey hotKey) {
    openAudio();
  });
}
class WindowData{
  late String type;
  int? id;
  late String title;
  late Map<String,String> data;

  WindowData(this.type, this.title, this.data);
  //toMap
  Map<String,String> toMap(){
    return {
      "type":type,
      "id":id.toString(),
      "title":title,
      ...data
    };
  }

  WindowData.build(int windowId, this.type, Map<String, String> args){
    id = windowId;
    title = args.remove("title") ?? "";
    data = args;
  }
}

abstract class WindowWidget extends StatelessWidget{
  final WindowController windowController;
  final WindowData data;

  const WindowWidget(this.windowController, this.data);
}

class TomotoWin extends StatelessWidget {
  const TomotoWin({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple.shade50),
        useMaterial3: true,
      ),
      home: Center(
        child: Text("fuck"),
      ),
      builder: EasyLoading.init(),
    );
  }
}
