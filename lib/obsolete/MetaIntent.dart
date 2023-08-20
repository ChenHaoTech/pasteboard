import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pasteboard/utils/logger.dart';


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
    return KeyboardBindingWidget(
      // metaIntentSet: meta_dig0_9.map((key, value) => MapEntry(value.$1, key)),
      metaIntentSet: {
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
      onMetaAction: (MetaIntent intent, BuildContext context) {
        logger.i("MetaIntentWidget, dig: ${intent} ");
        EasyLoading.showToast("fuck, ${intent.digKey}");
        onAction(intent.digKey);
      },
      child: child,
    );
  }
}

class KeyboardBindingWidget extends StatelessWidget {
  late Map<LogicalKeySet, Intent> metaIntentSet;
  late Function(MetaIntent intent, BuildContext context) onMetaAction;
  late Widget child;

  KeyboardBindingWidget({
    Key? key,
    required this.child,
    required this.onMetaAction,
    required this.metaIntentSet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: metaIntentSet,
      actions: <Type, Action<Intent>>{
        MetaIntent: CallbackAction<MetaIntent>(
          onInvoke: (MetaIntent intent) => onMetaAction.call(intent, context),
        ),
      },
      child: child,
    );
  }
}
