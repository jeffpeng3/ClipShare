import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';

abstract class ClipObserver {
  void onChanged(ContentType type, String content);
}

class ClipListener {
  static const String tag = "ClipListener";

  static final List<ClipObserver> _list = List.empty(growable: true);
  static final ClipListener _instance = ClipListener._private();

  ClipListener._private();

  static ClipListener get inst => _instance;

  ClipListener register(ClipObserver observer) {
    _list.add(observer);
    return this;
  }

  ClipListener remove(ClipObserver observer) {
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
