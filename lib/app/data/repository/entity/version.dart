import 'package:clipshare/app/utils/extension.dart';

class Version {
  final String name;
  final String code;

  int get codeNum => code.toInt();

  const Version(this.name, this.code);

  @override
  String toString() {
    return "$name($code)";
  }

  bool operator >=(Version other) {
    return codeNum >= other.codeNum;
  }

  bool operator <=(Version other) {
    return codeNum <= other.codeNum;
  }

  bool operator >(Version other) {
    return codeNum > other.codeNum;
  }

  bool operator <(Version other) {
    return codeNum < other.codeNum;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Version &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
