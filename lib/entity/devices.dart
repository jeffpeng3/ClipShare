import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';

class Devices {
  final Map<String, Device> _devices = {};

  Devices(List<Device> devices) {
    for (var dev in devices) {
      _devices[dev.guid] = dev;
    }
  }

  factory Devices.fromMap(Map<String, Device> devices) {
    var lst = devices.values.toList();
    return Devices(lst);
  }

  Device getById(String id) {
    if (_devices.containsKey(id)) {
      return _devices[id]!;
    }
    return id == App.device.guid
        ? App.device
        : Device.empty(devName: "unknown");
  }

  String getName(String id) {
    return getById(id).name;
  }

  Devices copyWith(Device dev) {
    _devices[dev.guid] = dev;
    return Devices.fromMap(_devices);
  }

  Map<String, String> toIdNameMap() {
    Map<String, String> res = {};
    _devices.forEach((key, value) {
      res[key] = value.name;
    });
    return res;
  }

  List<Device> get pairedList {
    return _devices.values.where((dev) => dev.isPaired).toList();
  }
}
