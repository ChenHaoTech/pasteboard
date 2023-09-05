import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/HotKeyService.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/markdown_page.dart';
import 'package:flutter_pasteboard/utils/logger.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'ClipboardVM.dart';
import 'home.dart';
import 'main_tomoto.dart';
import 'obsolete/MetaIntent.dart';

void main(List<String> args) async {
  if (args.firstOrNull == 'multi_window') {
    switch (args[2]) {
      case 'markdown':
        runApp(MarkdownPage());
        break;
      case "tomoto":
        // onMainArgsNewWindow(args);
        break;
      default:
        // throw UnimplementedError("args:${args}");
        return;
    }
  }
  //设置为 true 将导致焦点发生变化时发生大量日志记录。
  // debugFocusChanges = true;
  WidgetsFlutterBinding.ensureInitialized();
  Get.deleteAll(force: true);
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
  configLoading();
  var onError = FlutterError.onError; //先将 onerror 保存起来
  FlutterError.onError = (FlutterErrorDetails details) {
    onError?.call(details); //调用默认的onError
    // reportErrorAndLog(details); //上报
    //todo only 测试
    errorMsg.add(
        "${DateTime.now().toIso8601String()} ${details.exception} ${details.stack}");
    // Future.delayed(1.seconds, () {
    //   Get.to(FlutterErrorDetails(exception: details.exception, stack: details.stack));
    // });
  };
  runApp(const MyApp());

  // 使用了 runZoned 数据库加载不了了
  /*runZoned(
    () async {
      return
    },
    zoneSpecification: ZoneSpecification(
      // 拦截print
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        // collectLog(line);
        logger.i(line);
      },
      // 拦截未处理的异步错误
      handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
          Object error, StackTrace stackTrace) {
        // reportErrorAndLog(details);
        //todo only 测试
        errorMsg.add("${error.toString()} $stackTrace");
        hintError++;
        logger.e('${error.toString()} $stackTrace');
      },
    ),
  );*/
}

//todo only 测试环境
var errorMsg = [];
var hintError = 0.obs;

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

//todo 要想子界面 也接受对应的 action 和 shorcuts
Map<LogicalKeySet, CustomIntentWithAction> get globalKeyIntent {
  return {
    LogicalKeySet(KeyCode.keyD.logicalKey, LogicalKeyboardKey.control):
        CustomIntentWithAction("toggle_focus_debug", (context, intent) async {
      // debugFocusChanges = !debugFocusChanges;
      debugDumpFocusTree();
    }),
    LogicalKeySet(KeyCode.keyQ.logicalKey, LogicalKeyboardKey.control):
        CustomIntentWithAction("toggle_focus_log", (context, intent) async {
      print("fuck");
    }),
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      shortcuts: globalKeyIntent,
      actions: <Type, Action<CustomIntentWithAction>>{
        CustomIntentWithAction: CallbackAction<CustomIntentWithAction>(
          onInvoke: (CustomIntentWithAction intent) =>
              intent.func(context, intent),
        ),
      },
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
        GetPage(
          name: '/errorMsg',
          //todo only 测试
          page: () => Scaffold(
            body: ListView.builder(
                itemBuilder: (BuildContext context, int index) {
              return Text(errorMsg[index]);
            }),
          ),
        ),
      ],
      builder: (BuildContext context, Widget? child) {
        EasyLoading.init();
        hintError.listen((p0) {
          Get.toNamed("errorMsg");
        });
        return FlutterEasyLoading(child: child);
      }
    );
  }
}
