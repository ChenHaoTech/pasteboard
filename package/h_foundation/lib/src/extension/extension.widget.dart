// EasyShorcutsWidget 扩展 .shortcuts
import 'package:flutter/widgets.dart';
import 'package:h_foundation/src/extension/extension.obj.dart';

extension WidgetExt on Widget {
  //Column
  Widget Col({
    key,
    mainAxisAlignment,
    required MainAxisSize mainAxisSize,
    required CrossAxisAlignment crossAxisAlignment,
    TextDirection? textDirection,
    required VerticalDirection verticalDirection,
    TextBaseline? textBaseline,
    List<Widget>? children,
  }) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: [this].apply((it) {
        if(children!=null) it.addAll(children);
      }),
    );
  }

// center
  Widget center() {
    return Center(child: this);
  }

  // Focus
  Widget focus({
    FocusNode? focusNode,
    FocusNode? parentNode,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
    FocusOnKeyEventCallback? onKeyEvent,
    FocusOnKeyCallback? onKey,
    bool? canRequestFocus,
    bool? skipTraversal,
    bool? descendantsAreFocusable,
    bool? descendantsAreTraversable,
    bool includeSemantics = true,
    String? debugLabel,
  }) {
    return Focus(
        focusNode: focusNode,
        parentNode: parentNode,
        autofocus: autofocus,
        onFocusChange: onFocusChange,
        onKeyEvent: onKeyEvent,
        onKey: onKey,
        canRequestFocus: canRequestFocus,
        skipTraversal: skipTraversal,
        descendantsAreFocusable: descendantsAreFocusable,
        descendantsAreTraversable: descendantsAreTraversable,
        includeSemantics: includeSemantics,
        debugLabel: debugLabel,
        child: this);
  }

  // FocusTraversalGroup
  Widget easyFocusTraversal({
    FocusTraversalPolicy? policy,
    bool descendantsAreFocusable = true,
    bool descendantsAreTraversable = true,
  }) {
    return FocusTraversalGroup(
      descendantsAreFocusable: descendantsAreFocusable,
      policy: policy,
      descendantsAreTraversable: descendantsAreTraversable,
      child: this,
    );
  }

  Widget easyTap(
      {VoidCallback? onTap,
        VoidCallback? onDoubleTap,
        VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: this,
    );
  }
}