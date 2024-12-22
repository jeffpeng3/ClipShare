import 'package:clipshare/app/utils/extensions/string_extension.dart';

class AppVersion {
  final String name;
  final String code;

  int get codeNum => code.toInt();

  const AppVersion(this.name, this.code);

  @override
  String toString() {
    return "$name($code)";
  }

  bool operator >=(AppVersion other) {
    return codeNum >= other.codeNum;
  }

  bool operator <=(AppVersion other) {
    return codeNum <= other.codeNum;
  }

  bool operator >(AppVersion other) {
    return codeNum > other.codeNum;
  }

  bool operator <(AppVersion other) {
    return codeNum < other.codeNum;
  }

  int operator -(AppVersion other) {
    return codeNum - other.codeNum;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
