import 'package:desktop_drop/desktop_drop.dart';

class MyDropItem {
  final DropItem value;

  MyDropItem(this.value);

  @override
  int get hashCode => value.path.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is MyDropItem && runtimeType == other.runtimeType && value.path == other.value.path;
  }
}
