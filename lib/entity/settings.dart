class Settings {
  //端口
  int port;

  //本地名称（设备名称）
  String localName;

  //开机启动
  bool launchAtStartup;

  //启动最小化
  bool startMini;

  //允许自动发现
  bool allowDiscover;

  //显示历史悬浮窗
  bool showHistoryFloat;

  //是否第一次打开软件
  bool firstStartup;

  //RSA私钥
  final String privateKeyRSA;

  //RSA公钥
  final String publicKeyRSA;

  Settings({
    required this.port,
    required this.localName,
    required this.launchAtStartup,
    required this.startMini,
    required this.allowDiscover,
    required this.showHistoryFloat,
    required this.firstStartup,
    required this.privateKeyRSA,
    required this.publicKeyRSA,
  });

  Settings copyWith({
    int? port,
    String? localName,
    bool? launchAtStartup,
    bool? startMini,
    bool? allowDiscover,
    bool? showHistoryFloat,
    bool? firstStartup,
  }) {
    return Settings(
      port: port ?? this.port,
      localName: localName ?? this.localName,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      startMini: startMini ?? this.startMini,
      allowDiscover: allowDiscover ?? this.allowDiscover,
      showHistoryFloat: showHistoryFloat ?? this.showHistoryFloat,
      firstStartup: firstStartup ?? this.firstStartup,
      privateKeyRSA: privateKeyRSA,
      publicKeyRSA: publicKeyRSA,
    );
  }
}
