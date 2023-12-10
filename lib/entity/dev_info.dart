class DevInfo {
  String guid;
  String name;
  String type;

  DevInfo(this.guid, this.name, this.type);

  static DevInfo fromJson(Map<String, dynamic> map) {
    String guid = map["guid"];
    String name = map["name"];
    String type = map["type"];
    return DevInfo(guid, name, type);
  }

  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "name": name,
      "type": type,
    };
  }
}
