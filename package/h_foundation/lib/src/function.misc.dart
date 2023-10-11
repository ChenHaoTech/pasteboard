import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:h_foundation/h_foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// toast
void toast(String msg) {
  EasyLoading.show(status: msg, indicator: Center());
  Future.delayed(1.seconds, () {
    EasyLoading.dismiss();
  });
}

void wtoast(String msg) {
  EasyLoading.showError(msg);
  Future.delayed(1.seconds, () {
    EasyLoading.dismiss();
  });
}

//todo 改为 hive
late final SharedPreferences prefs;
ensureKVStore() async{
  // Obtain shared preferences.
  prefs = await SharedPreferences.getInstance();
  logger.d("[ensureKVStore] SharedPreferences.getInstance();");
}