import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

final metaAction = LogicalKeySet(
  LogicalKeyboardKey.meta, // Replace with control on Windows
  LogicalKeyboardKey.digit1,
);

class MetaIntent extends Intent {}

class MenuWidget extends StatelessWidget {
  late MetaIntent metaIntent;
  late Function(BuildContext context) onMetaAction;

  late Widget child;

  MenuWidget({
    Key? key,
    required this.metaIntent,
    required this.child,
    required this.onMetaAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: <LogicalKeySet, Intent>{metaAction: metaIntent},
      actions: <Type, Action<Intent>>{
        MetaIntent: CallbackAction<MetaIntent>(
          onInvoke: (MetaIntent intent) => onMetaAction.call(context),
        ),
      },
      child: child,
    );
  }
}
