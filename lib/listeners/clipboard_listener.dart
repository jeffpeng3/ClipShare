import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';

abstract class ClipObserver {
  void onChanged(ContentType type, String content);
}

class ClipboardListener {
  static const String tag = "ClipboardListener";

  static final List<ClipObserver> _list = List.empty(growable: true);
  static final ClipboardListener _instance = ClipboardListener._private();

  ClipboardListener._private();

  static ClipboardListener get inst => _instance;

  ClipboardListener register(ClipObserver observer) {
    _list.add(observer);
    return this;
  }

  ClipboardListener remove(ClipObserver observer) {
    _list.remove(observer);
    return this;
  }

  void update(ContentType type, String content) {
    for (var observer in _list) {
      try {
        observer.onChanged(type, content);
      } catch (e, stacktrace) {
        Log.debug(tag, e);
        Log.debug(tag, stacktrace);
      }
    }
  }
}
