extension MapExtension<T> on Iterable<T> {
  Iterable<R> map<R>(R mapper(T val)) {
    return this.map((item) => mapper(item));
  }
}