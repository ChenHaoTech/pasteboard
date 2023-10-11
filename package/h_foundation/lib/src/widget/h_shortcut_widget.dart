import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:h_foundation/h_foundation.dart';
import 'package:get/get.dart';

/*DEMO
KeyboardBindingWidget _test_buildKeyboardBindingWidget(
      CustomScrollView scrollView) {
    return KeyboardBindingWidget(
      onMetaAction: (MetaIntent intent, BuildContext context) {
        logger.i("MetaIntentWidget, dig: ${intent.digKey} ");
        EasyLoading.showSuccess("loading...");
        Future.delayed(0.milliseconds, () {
          windowManager.hide();
          PasteUtils.doAsyncPaste(pasteboardItems[intent.digKey]);
        });
      },
      metaIntentSet: {meta_1: MetaIntent(1)},
      child: scrollView,
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
* */
/*meta+ dig0~9*/
final meta_0 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit0,
);
final meta_1 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit1,
);
final meta_2 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit2,
);
final meta_3 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit3,
);
final meta_4 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit4,
);
final meta_5 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit5,
);
final meta_6 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit6,
);
final meta_7 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit7,
);
final meta_8 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit8,
);
final meta_9 = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit9,
);
// EasyShorcutsWidget 扩展 .shortcuts
extension EasyShorcutsWidgetExt on Widget {
  // .shortcuts
  Widget easyShortcuts(
      {Map<LogicalKeySet, CustomIntentWithAction>? intentSet}) {
    return EasyShorcutsWidget(
      intentSet: intentSet,
      child: this,
    );
  }
}
// 实现一个绑定 meta_0 meta_9 的 widget, 暴露 一个 onMetaList 列表和 child
// 通过 onMetaList 来绑定 meta_0 meta_9 的行为

class MetaIntent extends Intent {
  late int digKey;

  MetaIntent(this.digKey);
}

class MetaIntentWidget extends StatelessWidget {
  late Function(int digKey) onAction;
  late Widget child;

  MetaIntentWidget({
    Key? key,
    required this.child,
    required this.onAction,
  }) : super(key: key) {}

  @override
  Widget build(BuildContext context) {
    var keyMap = {};
    return MyFocusableActionWidget(
      // metaIntentSet: meta_dig0_9.map((key, value) => MapEntry(value.$1, key)),
      intentSet: {
        meta_0: MetaIntent(0),
        meta_1: MetaIntent(1),
        meta_2: MetaIntent(2),
        meta_3: MetaIntent(3),
        meta_4: MetaIntent(4),
        meta_5: MetaIntent(5),
        meta_6: MetaIntent(6),
        meta_7: MetaIntent(7),
        meta_8: MetaIntent(8),
        meta_9: MetaIntent(9),
      },
      onAction: (Intent intent, BuildContext context) {
        // if()
        // logger.i("MetaIntentWidget, dig: ${intent} ");
        // EasyLoading.showToast("fuck, ${intent.digKey}");
        // onAction(intent.digKey);
      },
      child: child,
    );
  }
}

class CustomIntent extends Intent {
  final dynamic data;
  final String key;

  const CustomIntent(this.key, {this.data});
}

class CustomIntentWithAction extends Intent {
  final dynamic data;
  final String key;
  final Future<void> Function(BuildContext context, CustomIntentWithAction intent) func;

  CustomIntentWithAction(this.func, {this.key = "", this.data});
}

class EasyShorcutsWidget extends StatelessWidget {
  final Map<LogicalKeySet, CustomIntentWithAction>? intentSet;
  final Widget child;

  EasyShorcutsWidget({this.intentSet, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MyFocusableActionWidget<CustomIntentWithAction>(
      intentSet: intentSet ?? {},
      onAction: (CustomIntentWithAction intent, BuildContext context) {
        intent.func.call(context, intent);
      },
      focusNode: FocusNode(skipTraversal: true),
      child: child,);
  }

}

class MyFocusableActionWidget<T extends Intent> extends StatelessWidget {
  final Map<LogicalKeySet, T> intentSet;
  final Function(T intent, BuildContext context) onAction;
  final Widget child;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final enableIntent = RxBool(true);

  final Function(bool, MyFocusableActionWidget)? onFocusChange;

  final KeyEventResult Function(FocusNode node, RawKeyEvent event)? onRawKeyEvent;

  MyFocusableActionWidget({
    Key? key,
    required this.child,
    required this.onAction,
    required this.intentSet,
    this.focusNode,
    this.onKeyEvent,
    this.onRawKeyEvent,
    this.onFocusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildFocusableActionDetector(context);
  }

  FocusableActionDetector buildFocusableActionDetector(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (bool focus) {
        onFocusChange?.call(focus, this);
      },
      autofocus: true, // 没有这个 flutter 在 mac 端直接异常了, 起不来
      focusNode: (focusNode ?? FocusNode()).apply((p0) {
        p0.skipTraversal= true; // FocusableActionDetector 自己不在 focus 变化序列里
        p0.onKeyEvent = this.onKeyEvent;
        p0.onKey = (FocusNode node, RawKeyEvent event){
          var res = onRawKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
          if (event.isMetaPressed && (event.character ?? "") != "") {
            //todo 还没修好
            SchedulerBinding.instance.addPostFrameCallback((_) {
              // ignore: invalid_use_of_visible_for_testing_member
              RawKeyboard.instance.clearKeysPressed();
            });
          }
          return res;
        };
      }),
      shortcuts: intentSet,
      actions: <Type, Action<Intent>>{
        T: CallbackAction<T>(
          onInvoke: (T intent) => onAction.call(intent, context),
        ),
      },
      child: child,
    );
  }
}
