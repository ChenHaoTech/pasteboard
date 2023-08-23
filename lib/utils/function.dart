// 模仿 kotlin 实现 let、also、apply、run、with、takeIf、takeUnless
extension ObjectExtensions<T> on T {
  R let<R>(R Function(T) block) => block(this);

  T also(void Function(T) block) {
    block(this);
    return this;
  }

  T apply(void Function(T) block) {
    block(this);
    return this;
  }

  R run<R>(R Function(T) block) => block(this);

  R dwith<R>(R Function(T) block) => block(this);

  T? takeIf(bool Function(T) predicate) {
    if (predicate(this)) {
      return this;
    }
    return null;
  }

  T? takeUnless(bool Function(T) predicate) {
    if (!predicate(this)) {
      return this;
    }
    return null;
  }
}

void main() {
  'Hello'.let((it) => print(it.length));

  'Hello'.also((it) => print(it.length));

  'Hello'.apply((it) => print(it.length));

  'Hello'.run((it) => print(it.length));

  'Hello'.dwith((it) => print(it.length));

  'Hello'.takeIf((it) => it.length > 5);

  'Hello'.takeUnless((it) => it.length > 5);
}
