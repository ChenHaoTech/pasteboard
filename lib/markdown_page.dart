import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:get/get.dart';

/**
 *
 * @author chenhao91
 * @date   2023/8/22
 */
class MarkdownPage extends StatelessWidget{
  MarkdownPage({Key? key}) : super(key: key);
  final ClipboardVM clipboardVM = Get.find<ClipboardVM>();


  @override
  Widget build(BuildContext context) {
    var obx = Obx((){
      var context = clipboardVM.editMarkdownContext.value;
      // EasyLoading.showSuccess("status");
      var textField = TextField(
        controller: TextEditingController(text:context),
        decoration: const InputDecoration(border: InputBorder.none),
        maxLines: null,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) {
          clipboardVM.editMarkdownContext.value = value;
        },
      );
      return textField;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Markdown Mode"),
        actions: [
          IconButton(
              onPressed: () {
                clipboardVM.alwaysOnTop.value = !clipboardVM.alwaysOnTop.value;
              },
              icon: Obx(() {
                return Icon(clipboardVM.alwaysOnTop.value
                    ? Icons.push_pin
                    : Icons.push_pin_outlined);
              })),
        ],
      ),
      body: obx,
    );
  }
}
