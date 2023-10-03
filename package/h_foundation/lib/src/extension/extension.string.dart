// 对于字符串 强转的 工具 toIntOrNull toFloatOrNull 等
extension StringExtension on String {
  int? toIntOrNull() {
    try {
      return int.parse(this);
    } catch (e) {
      return null;
    }
  }

  double? toDoubleOrNull() {
    try {
      return double.parse(this);
    } catch (e) {
      return null;
    }
  }
}
