import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/pasteboard_item.dart';

class PasteboardItemView extends StatelessWidget {
  const PasteboardItemView({
    Key? key,
    required this.item,
    required this.index,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

// default: item, button
  final int index;
  final PasteboardItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 1),
      child: Material(
        borderRadius: BorderRadius.circular(6),
        // color: getColor(index),
        // color: Colors.deepPurple.shade50,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap == null ? null : () => onTap!(),
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
    if (item.type == 0 && item.text != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              // 文字
              item.text!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Text(
            "cmd+${index+1}",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      );
    } else if (item.type == 1 && item.image != null && item.image!.isNotEmpty) {
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
            "cmd+${index+1}",
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
