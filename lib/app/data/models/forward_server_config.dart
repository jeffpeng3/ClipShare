import 'dart:convert';

class ForwardServerConfig {
  String host;
  int port;
  String? key;

  String get server => "$host:$port";

  ForwardServerConfig({
    required this.host,
    required this.port,
    this.key,
  });

  factory ForwardServerConfig.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    String? key = data.containsKey("key")
        ? data["key"] == ""
            ? null
            : data["key"]
        : null;
    return ForwardServerConfig(
      host: data["host"],
      port: data["port"],
      key: key,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "host": host,
      "port": port,
      "key": key,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
