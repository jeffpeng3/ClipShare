import 'package:clipshare/app/utils/log.dart';

abstract mixin class ScreenOpenedObserver {
  void onScreenOpened(){}

  void onScreenClosed(){}
}

class ScreenOpenedListener {
  static const String tag = "ScreenOpenedListener";

  static final List<ScreenOpenedObserver> _list = List.empty(growable: true);
  static final ScreenOpenedListener _instance = ScreenOpenedListener._private();

  ScreenOpenedListener._private();

  static ScreenOpenedListener get inst => _instance;

  ScreenOpenedListener register(ScreenOpenedObserver observer) {
    _list.add(observer);
    return this;
  }

  ScreenOpenedListener remove(ScreenOpenedObserver observer) {
    _list.remove(observer);
    return this;
  }

  void notify(bool open) {
    for (var observer in _list) {
      try {
        if (open) {
          observer.onScreenOpened();
        } else {
          observer.onScreenClosed();
        }
      } catch (e, stacktrace) {
        Log.debug(tag, e);
        Log.debug(tag, stacktrace);
      }
    }
  }
}
