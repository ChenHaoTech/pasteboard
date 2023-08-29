import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pasteboard/obsolete/MetaIntent.dart';
import 'package:flutter_pasteboard/utils/function.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';

class PasteboardItemView extends StatelessWidget {
  PasteboardItemView({
    Key? key,
    required this.item,
    required this.index,
    this.onTap,
    this.onLongPress,
    this.color, this.focusNode,
  }) : super(key: key);

  final FocusNode? focusNode;
// default: item, button
  final int index;
  final Color? color;
  final PasteboardItem item;
  final VoidCallback? onTap;

  // final ValueChanged<bool>? onHover;
  final VoidCallback? onLongPress;
  var hover = Rx(false);

  @override
  Widget build(BuildContext context) {
    return MyFocusableActionWidget<CustomIntentWithAction>(
      focusNode: FocusNode().apply((it) {
        it.skipTraversal = true;
      }),
      onAction: (CustomIntentWithAction intent, BuildContext context) {
        intent.func(context, intent);
      },
      intentSet: {
        LogicalKeySet(LogicalKeyboardKey.keyK, LogicalKeyboardKey.meta):
            CustomIntentWithAction("meta_k", (context, intent) async {
          toast("meta_k");
        }),
      },
      child: buildContainer(context),
    );
  }

  Container buildContainer(BuildContext context) {
    var inkWell = InkWell(
      onFocusChange: (focus) {
        if (focus) {
          PasteboardItem.current = item;
        }
      },
      focusNode: (focusNode ?? FocusNode()).apply((it) {
        item.focusNode = it;
      }),
      onTap: onTap == null ? null : () => onTap!(),
      onHover: (hovering) {
        hover.value = hovering;
        // EasyLoading.showSuccess("hover: $hovering");
      },
      onLongPress: onLongPress == null ? null : () => onLongPress!(),
      child: Ink(
          padding:
              const EdgeInsets.only(left: 10, top: 4, bottom: 4, right: 10),
          child: _getWidget(item, context)),
    );
    return Container(
        color: color,
        padding:
            const EdgeInsets.only(left: 1.5, right: 1.5, top: 1, bottom: 1),
        child: Material(
          borderRadius: BorderRadius.circular(0.5),
          // color: getColor(index),
          // color: Colors.deepPurple.shade50,
          child: inkWell,
        ));
  }

  Widget _getWidget(PasteboardItem item, BuildContext context) {
    hover.value = false;
    if(item.type==PasteboardItemType.html){
    return  Row(
          children: [
            Expanded(
              child: Text(
                // 文字
                item.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 13),
              ),
            ),
            Text(
              index < 9 ? "cmd+${index + 1}" : "",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ]);
    }

    //todo 性能不够高啊
    // 替换 换行符, 如果前后有空格的 也换掉
    var text = item.text!.replaceAll("\n", " ").replaceAll("  ", " ");
    if (item.type == PasteboardItemType.text) {
      return Row(
        children: [
          Expanded(
            child: Text(
              // 文字
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13),
            ),
          ),
          Text(
            index < 9 ? "cmd+${index + 1}" : "",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      );
    } else if (item.type == PasteboardItemType.image &&
        item.image != null &&
        item.image!.isNotEmpty) {
      // 图片
      return Row(
        children: [
          Expanded(
              child: Image.memory(
            item.image!,
            width: double.infinity,
            height: 40,
            fit: BoxFit.cover,
          )),
          Text(
            index < 9 ? "cmd+${index + 1}" : "",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      );
    }
    return Container();
  }

  Color getColor(int index) {
    if (index % 2 == 0) {
      return Colors.deepPurple.shade50;
    } else {
      return Colors.deepPurple.shade50;
    }
  }
}
