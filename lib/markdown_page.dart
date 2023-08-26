import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/utils/SimpleGetController.dart';
import 'package:flutter_pasteboard/utils/function.dart';
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
      autofocus: true,
      controller: controller,
      decoration: InputDecoration(border: InputBorder.none,
          hintText: "The content you copied will automatically come here. "
              "\n😘Try cmd c to copy something",
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8)),
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
          var insertPos = selection.extentOffset;
          if (insertPos <= 0 || insertPos >= origin.length) {
            insertPos = origin.length;
            p0 = "\n$p0";
          }
          controller.text =
              "${origin.substring(0, insertPos)}$p0${origin.substring(insertPos)}";
          print("controller.text = ${controller.text}");
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: insertPos + p0.length));
        });
      }),
      builder: (sc) {
        return textField;
      },
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
          icon: const Icon(Icons.arrow_back_ios_sharp),
          iconSize: 16,
        ),
        title: const Text("Markdown Mode", style: TextStyle(fontSize: 15),),
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
