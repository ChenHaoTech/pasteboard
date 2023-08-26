import 'dart:async';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SimpleGetController extends GetxController {
  final StreamSubscription? Function()? onInitFunc;
  final StreamSubscription? Function()? onReadyFunc;
  final Function? disposeFunc;
  final Function? onCloseFunc;
  StreamSubscription? sub;

  SimpleGetController(
      {this.onInitFunc, this.onReadyFunc, this.disposeFunc, this.onCloseFunc});

  @override
  void onInit() {
    super.onInit();
    sub = onInitFunc?.call();
  }

  @override
  void onReady() {
    super.onReady();
    sub = onReadyFunc?.call();
  }

  @override
  void dispose() {
    super.dispose();
    sub?.cancel();
    disposeFunc?.call();
  }

  @override
  void onClose() {
    super.onClose();
    sub?.cancel();
    print("sub: $sub");
    onCloseFunc?.call();
  }
}