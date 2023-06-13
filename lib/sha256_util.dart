import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class SHA256Util {
  static String calculateSHA256(Uint8List data) {
    var digest = sha256.convert(data);
    return digest.toString();
  }

  // 使用SHA-256算法对文本进行唯一性校验
  static String calculateSHA256ForText(String text) {
    var bytes = utf8.encode(text);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
