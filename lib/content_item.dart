import 'package:flutter/material.dart';

class ContentItem extends StatelessWidget {
  const ContentItem({
    Key? key,
    required this.text,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  final String text;
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
              child: Text(
                text,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              )),
        ),
      ),
    );
  }

  Color getColor(int index) {
    if (index % 2 == 0) {
      return Colors.deepPurple.shade50;
    } else {
      return Colors.deepPurple.shade50;
    }
  }
}
