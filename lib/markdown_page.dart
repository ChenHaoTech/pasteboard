import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/utils/SimpleGetController.dart';
import 'package:get/get.dart';

/**
 *
 * @author chenhao91
 * @date   2023/8/22
 */
class MarkdownPage extends StatelessWidget {
  MarkdownPage({Key? key}) : super(key: key);
  final ClipboardVM clipboardVM = Get.find<ClipboardVM>();

  @override
  Widget build(BuildContext context) {
    var controller =
        TextEditingController(text: clipboardVM.editMarkdownContext);
    var textField = TextField(
      controller: controller,
      decoration: const InputDecoration(border: InputBorder.none),
      maxLines: null,
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        clipboardVM.editMarkdownContext = value;
      },
    );
    var core = GetBuilder(
      init: SimpleGetController(onReadyFunc: () {
        return clipboardVM.lastClipTxt.listen((p0) {
          var origin=controller.text;
          var selection = controller.selection;
          var curOffset = selection.extentOffset;
          if(curOffset<0 || curOffset>origin.length){
            curOffset = origin.length;
          }
          controller.text = origin.substring(0, curOffset) +
              "${p0}" +
              origin.substring(curOffset);
        });
      }),
      builder: (sc) {
        return textField;
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Markdown Mode"),
        actions: [
          IconButton(onPressed: () {
            clipboardVM.alwaysOnTop.value = !clipboardVM.alwaysOnTop.value;
          }, icon: Obx(() {
            return Icon(clipboardVM.alwaysOnTop.value
                ? Icons.push_pin
                : Icons.push_pin_outlined);
          })),
        ],
      ),
      body: core,
    );
  }
}
