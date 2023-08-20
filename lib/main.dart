import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';
import 'package:flutter_pasteboard/utils/logger.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'home.dart';
import 'vm_view/pasteboard_item_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  logger.i("windowManager.ensureInitialized() begin");
  await windowManager.ensureInitialized();
  logger.i("windowManager.ensureInitialized()");
  await hotKeyManager.unregisterAll();
  logger.i("hotKeyManager.unregisterAll()");
  WindowOptions windowOptions = const WindowOptions(
    size: Size(210 * 3, 350),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
  });
  // windowManager.hide();
  windowManager.show();
  windowManager.setMovable(false);
  windowManager.setResizable(false);
  logger.i("windowManager.show()");
  Get.put(ClipboardVM());
  runApp(const MyApp());
  configLoading();
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
      builder: EasyLoading.init(),
    );
  }
}
