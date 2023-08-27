import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:get/get.dart';

/**
 *
 * @author chenhao91
 * @date   2023/8/22
 */
class MarkdownPage extends StatefulWidget {
  const MarkdownPage({Key? key}) : super(key: key);

  MarkdownPageState createState() => MarkdownPageState();
}

class MarkdownPageState extends State<MarkdownPage> {
  final ClipboardVM clipboardVM = Get.find<ClipboardVM>();
  final WindowService windowService = Get.find<WindowService>();

  late TextEditingController textController;
  late StreamSubscription sub;

  @override
  void initState() {
    super.initState();
    textController =
        TextEditingController(text: clipboardVM.editMarkdownContext);
    sub = clipboardVM.lastClipTxt.listen((p0) async {
      if (await windowService.isFocus()) return;
      var origin = textController.text;
      var selection = textController.selection;
      var insertPos = selection.extentOffset;
      if (insertPos <= 0 || insertPos >= origin.length) {
        insertPos = origin.length;
        p0 = "\n$p0";
      }
      textController.text =
          "${origin.substring(0, insertPos)}$p0${origin.substring(insertPos)}";
      print("controller.text = ${textController.text}");
      textController.selection = TextSelection.fromPosition(
          TextPosition(offset: insertPos + p0.length));
    });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var textField = TextField(
      autofocus: true,
      controller: textController,
      decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "The content you copied will automatically come here. "
              "\n😘Try cmd c to copy something",
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          contentPadding:
              const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8)),
      maxLines: null,
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        clipboardVM.editMarkdownContext = value;
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
        title: const Text(
          "Markdown Mode",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(onPressed: () {
            windowService.alwaysOnTop.value = !windowService.alwaysOnTop.value;
          }, icon: Obx(() {
            return Icon(windowService.alwaysOnTop.value
                ? Icons.push_pin
                : Icons.push_pin_outlined);
          })),
        ],
      ),
      body: textField,
    );
  }
}
