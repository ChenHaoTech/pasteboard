import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pasteboard/ClipboardVM.dart';
import 'package:flutter_pasteboard/WindowService.dart';
import 'package:flutter_pasteboard/obsolete/MetaIntent.dart';
import 'package:flutter_pasteboard/single_service.dart';
import 'package:flutter_pasteboard/utils/function.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:markdown_widget/markdown_widget.dart';


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
  late TextEditingController textController;
  late StreamSubscription sub;

  @override
  void initState() {
    super.initState();
    windowService.autoFocusOnWindowShow = _markdownEdit;
    _markdownEdit.requestFocus();
    textController =
        TextEditingController(text: clipboardVM.editMarkdownContext);
    sub = clipboardVM.lastClipTxt.listen((p0) async {
      if (await windowService.isFocus()) return;
      var origin = textController.text;
      var selection = textController.selection;
      var insertPos = selection.extentOffset;
      var needScrolltoBottom = false;
      if (insertPos <= 0 || insertPos >= origin.length) {
        insertPos = origin.length;
        p0 = "\n$p0";
        needScrolltoBottom = true;
      }
      textController.text =
          "${origin.substring(0, insertPos)}$p0${origin.substring(insertPos)}";

      if(true){
        await Future.delayed(100.milliseconds);
        textController.selection = TextSelection.fromPosition(
            TextPosition(offset: insertPos + p0.length));
        // 到结尾
        // _scrollController.jumpTo()
      }
    });
    // todo 获取剪切板这一套 还不行 看看 biyi
    // hotKeyManager.register(
    //     HotKey(KeyCode.keyC, modifiers: [KeyModifier.meta, KeyModifier.shift]),
    //     keyDownHandler: (hotkey) async{
    //       await keyPressSimulator.simulateCtrlCKeyPress();
    //       print("await keyPressSimulator.simulateCtrlCKeyPress();");
    //       Future.delayed(100.milliseconds,(){
    //         windowService.requestWindowShow();
    //       });
    //     });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
    windowService.autoFocusOnWindowShow = null;
    _markdownEdit.dispose();
  }

  final FocusNode _markdownEdit = FocusNode(debugLabel: "markdownEdit");
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // 没有编辑功能
    var md = const MarkdownWidget(
      data: "clipboardVM.editMarkdownContext",
    );
    var textField = TextField(
      scrollController: _scrollController,
      autofocus: true,
      focusNode: _markdownEdit,
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
