import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/vm_view/pasteboard_item.dart';
import 'package:get/get.dart';

class PasteboardItemView extends StatelessWidget {
  PasteboardItemView({
    Key? key,
    required this.item,
    required this.index,
    this.onTap,
    this.onLongPress,
    this.color,
    this.focusNode,
  }) : super(key: key);

// default: item, button
  final int index;
  final Color? color;
  final PasteboardItem item;
  final VoidCallback? onTap;

  // final ValueChanged<bool>? onHover;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  var hover = Rx(false);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 1),
      child: Material(
        borderRadius: BorderRadius.circular(6),
        // color: getColor(index),
        // color: Colors.deepPurple.shade50,
        child: InkWell(
          focusNode: focusNode ?? FocusNode(),
          borderRadius: BorderRadius.circular(6),
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
        ),
      ),
    );
  }

  Widget _getWidget(PasteboardItem item, BuildContext context) {
    hover.value = false;
    var text = item.text;
    if (item.type == PasteboardItemType.text && text != null) {
      var maxLine = 3;
      return Row(
        children: [
          Expanded(
            child: Obx(() {
              var isHovering= hover.value;
              if(isHovering && false){
                maxLine = 100;
                // EasyLoading.showSuccess("maxLine: $maxLine");
              }else{
                var split = text!.split("\n");
                text = split.length > maxLine ? "${split.sublist(0, maxLine).join("\n")}..." : text;
              }
              return Text(
                // 文字
                text!,
                maxLines: maxLine,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.secondary,fontSize: 13),
              );
            }),
          ),
          Text(
            index < 9 ? "cmd+${index + 1}" : "",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      );
    } else if (item.type == PasteboardItemType.image && item.image != null && item.image!.isNotEmpty) {
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
