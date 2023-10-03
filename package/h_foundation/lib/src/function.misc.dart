import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

// toast
void toast(String msg) {
  EasyLoading.show(status: msg, indicator: Center());
  Future.delayed(1.seconds, () {
    EasyLoading.dismiss();
  });
}
