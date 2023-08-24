import 'dart:async';
import 'dart:io';

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
openAudio(){
  // 注意不要泄漏了
  AudioPlayer().play(AssetSource('1.mp3'));
}

final SystemTray systemTray = SystemTray();
Future<void> initSystemTray() async {
  //todo 支持 windows
  if (Platform.isWindows) return;
  String path = 'asserts/app_icon.png';

  final AppWindow appWindow = AppWindow();

  // We first init the systray menu
  await systemTray.initSystemTray(
    title: "system tray",
    iconPath: path,
  );

  // create context menu
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
    MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
    MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
  ]);
  // 每隔一秒 刷新下 title
  // Timer.periodic(const Duration(seconds: 1), (timer) {
  //   systemTray.setTitle(DateTime.now().toString());
  // });

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
  initSystemTray();
  // // Must add this line.
  await hotKeyManager.unregisterAll();

  hotKeyManager.register(HotKey(
    KeyCode.keyC,
    modifiers: [
      KeyModifier.control,
    ],
    // Set hotkey scope (default is HotKeyScope.system)
    scope: HotKeyScope.system, // Set as inapp-wide hotkey.
  ),keyDownHandler: (HotKey hotKey) {
      openAudio();
  });
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
  runApp(const MyApp());
  // configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
  // ..customAnimation = CustomAnimation();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
