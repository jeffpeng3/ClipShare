class Constants {
  static const int port = 42317;
  static const String multicastGroup = '224.0.0.128';
  static const heartbeatsSeconds = 10;
}

enum MsgKey {
  history,
  heartbeats,
  ackSync,
  discover;

  static MsgKey getValue(String name) =>
      MsgKey.values.firstWhere((e) => e.name == name);
}
