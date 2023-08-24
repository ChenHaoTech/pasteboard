// 模仿 kotlin 实现 let、also、apply、run、with、takeIf、takeUnless

import 'package:flutter_easyloading/flutter_easyloading.dart';

extension MapExtension<T> on Iterable<T> {
  Iterable<R> map<R>(R mapper(T val)) {
    return this.map((item) => mapper(item));
  }
}

extension ObjectExtensions<T> on T {
  R map<R>(R mapper(T val)) {
    return mapper(this);
  }

  R let<R>(R Function(T it) block) => block(this);

  T apply(void Function(T it) block) {
    block(this);
    return this;
  }

  R run<R>(R Function(T it) block) => block(this);

  T? takeIf(bool Function(T it) predicate) {
    if (predicate(this)) {
      return this;
    }
    return null;
  }

  T? takeUnless(bool Function(T it) predicate) {
    if (!predicate(this)) {
      return this;
    }
    return null;
  }
}

// toast
void toast(String msg) {
  EasyLoading.show(status: msg);
}

void main() {
  'Hello'.let((it) => print(it.length));
  'Hello'.apply((it) => print(it.length));

  'Hello'.run((it) => print(it.length));

  'Hello'.takeIf((it) => it.length > 5);

  'Hello'.takeUnless((it) => it.length > 5);
}
