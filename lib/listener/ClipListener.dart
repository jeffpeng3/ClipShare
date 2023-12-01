abstract class ClipObserver {
  void onChanged(String content);
}

class ClipListener {
  static final List<ClipObserver> _list = List.empty(growable: true);
  static final ClipListener _instance = ClipListener._private();

  ClipListener._private();

  factory ClipListener.instance() {
    return _instance;
  }

  ClipListener register(ClipObserver observer) {
    _list.add(observer);
    return this;
  }

  ClipListener remove(ClipObserver observer) {
    _list.remove(observer);
    return this;
  }

  void setClip(String content) {
    for (var observer in _list) {
      try {
        observer.onChanged(content);
      } catch (e, stacktrace) {
        print(e);
        print(stacktrace);
      }
    }
  }
}
