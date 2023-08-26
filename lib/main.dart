import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/HotKeyService.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/markdown_page.dart';
import 'package:flutter_pasteboard/sample/_ExampleMainWindow.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'ClipboardVM.dart';
import 'home.dart';
import 'main_tomoto.dart';

void main(List<String> args) async {
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    runApp(ExampleSubWindow(
      windowController: WindowController.fromWindowId(windowId),
      args: argument,
    ));
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  await tomotoBinding();
  // Must add this line.
  await windowManager.ensureInitialized();
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
  // windowManager.show();
  windowManager.setMovable(true);
  windowManager.setResizable(true);
  windowManager.setVisibleOnAllWorkspaces(false);
  Get.put(ClipboardVM());
  Get.put(HotKeySerice());
  Get.put(WindowService());
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
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple.shade50),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
      getPages: [
        GetPage(
          name: '/home',
          page: () => const Text("welcome"),
        ),
        GetPage(
          name: '/markdown',
          page: () => MarkdownPage(),
        ),
      ],
      builder: EasyLoading.init(),
    );
  }
}
