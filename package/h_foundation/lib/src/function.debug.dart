import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:h_foundation/h_foundation.dart';
import 'package:h_foundation/src/logger.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:overlayment/overlayment.dart';

import 'global_conf.dart';

void $assert(bool condition, [String msg = ""]) {
  // 具有更多的可配置项
  if(!condition){
    logger.e(msg);
    _showError(msg);
  }
  assert(condition, msg);
  //todo 缺上报给指定平台
}

void _showError(String msg) {
  Get.to(() => _myErrorsHandler.defaultErrorWidgetBuilder(FlutterErrorDetails(exception: Exception(msg))));
}

void ensureDebug(){
  Get.put(DebugUtils());
  RawKeyboard.instance.addListener((value) {
    if(kDebugKeyboard) {
      logger.d("[RawKeyboard]value: $value");
    }
  });
  logger.d("ensureDebug");
}
ensureErrorHandlePrepare() async {
  await _myErrorsHandler.initialize();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _myErrorsHandler.onErrorDetails(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e("[error]", error, stack);
    _myErrorsHandler.onError(error, stack);
    return true;
  };
  ErrorWidget.builder = _myErrorsHandler.defaultErrorWidgetBuilder;
}
var _myErrorsHandler = MyErrorsHandler(ErrorWidget.builder);
class MyErrorsHandler{
  MyErrorsHandler(this._defaultBuilder);
  final ErrorWidgetBuilder _defaultBuilder;

  initialize() async {

  }
  onError(Object exception, StackTrace stackTrace){
    _showError("${exception}\n ${stackTrace}");
  }
  onErrorDetails(FlutterErrorDetails details){
    _showError("${details.exception}\n${details.stack}");
  }

  Widget defaultErrorWidgetBuilder(FlutterErrorDetails details) {
    return Scaffold(
        backgroundColor: Colors.red,
        body: TextField(
          maxLines: null,
          controller: TextEditingController(text: details.exception.toString()),
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 8 * 3, bottom: 8)),
        )
    );
  }
}

class DebugUtils extends GetxService {
  static DebugUtils get instance => Get.find<DebugUtils>();
  final RxList<Widget Function()> _supplier = RxList();
  final List<Widget> _debugWindowList = [];
  final show = RxBool(prefs.getBool("DebugUtils.show") ?? false).apply((it) {
    it.listen((p0) {
      prefs.setBool("DebugUtils.show", p0);
    });
  });

  final RxInt _hintUpdate = RxInt(0);
  final String _debugWindowName = "DEBUG_WINDOW";

  OverWindow _debugWindow() {
    return OverWindow(
        name: _debugWindowName,
        position: const Offset(50, 50),
        canMove: true,
        color: Colors.transparent,
        animation: const OverFadeAnimation(durationMilliseconds: 10, reverseDurationMilliseconds: 10, child: OverScaleAnimation()),
        backgroundSettings: BackgroundSettings.transparent(false),
        child: Obx(() {
          _hintUpdate.value;
          // todo 宽高 布局约束 学习
          var list = ListView(children: _debugWindowList);
          var size = Get.context?.size ?? const Size(400, 600);
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: 0, minWidth: 0, maxWidth: size.width * 0.8, maxHeight: size.height * 0.8),
            child: list,
          );
        })).apply((it) {
      Overlayment.navigationKey = Get.key;
    });
  }

  @override
  void onInit() {
    super.onInit();
    show.listen((p0) async {
      await _show(p0);
      _supplier.refresh();
    });
    _supplier.listen((p0) {
      var list = p0.map((e) => e());
      _debugWindowList.clear();
      _debugWindowList.addAll(list);
      _hintUpdate.value++;
    });
    //DebugUtils.instance.show.toggle();
    hotKeyManager.register(
        HotKey(
          KeyCode.keyD,
          modifiers: [KeyModifier.meta, KeyModifier.control],
          // Set hotkey scope (default is HotKeyScope.system)
        ), keyDownHandler: (hotKey) async {
      logger.d("),keyDownHandler:  (hotKey) async {");
      show.toggle();
    });
    // _show(show.value);
  }

  Future<void> _show(bool p0) async {
    logger.d("show.listen((p0) async {");
    if (p0) {
      await Overlayment.show(_debugWindow());
    } else {
      await Overlayment.dismissName(_debugWindowName);
    }
  }
}

extension DebugUtilsEx on DebugUtils {
  addLabel(Rx<dynamic> label,Rx<dynamic> title) {
    _supplier.add(() => Obx(() => Text("${label.value.toString()}: ${title.value.toString()}")));
  }

  // add check box
  addCheckBox(Rx<String> label,Rx<bool> value ) {
    _supplier.add(() => Obx(() {
      var list = [
        Text(label.value),
        Checkbox(
            value: value.value,
            onChanged: (bool? v) {
              v?.let((it) => value.value = it);
            })
      ];
      return Row(children: list);
    }));
  }

  // add TextEditor
  addTextField(Rx<String> label, Rx<String> value) {
    _supplier.add(
          () => Obx(
            () {
          var list = [
            Text(label.value),
            TextField(
              maxLines: 1,
              controller: TextEditingController(text: value.value),
              decoration : InputDecoration(constraints: BoxConstraints.tightFor(height: 42,width: 400)),
              onChanged: (String? v) {
                v?.let((it) => value.value = it);
              },
            )
          ];
          return Row(
            children: list,
          );
        },
      ),
    );
  }
}