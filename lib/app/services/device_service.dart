import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class DeviceService extends GetxController {
  final _dbService = Get.find<DbService>();
  final _appConfig = Get.find<ConfigService>();
  final _devices = <String, Device>{}.obs;

  Future<DeviceService> init() async {
    final lst = await _dbService.deviceDao.getAllDevices(_appConfig.userId);
    for (var dev in lst) {
      _devices[dev.guid] = dev;
    }
    return this;
  }

  Device getById(String id) {
    if (_devices.containsKey(id)) {
      return _devices[id]!;
    }
    return id == _appConfig.device.guid
        ? _appConfig.device
        : Device.empty(devName: "unknown");
  }

  String getName(String id) {
    return getById(id).name;
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

  Future<bool> _addOrUpdate(Device device) async {
    var v = await _dbService.deviceDao.getById(device.guid, _appConfig.userId);
    if (v == null) {
      return await _dbService.deviceDao.add(device) > 0;
    } else {
      return await _dbService.deviceDao.updateDevice(device) > 0;
    }
  }

  Future<bool> addOrUpdate(Device device) async {
    var res = await _addOrUpdate(device);
    if (res) {
      _devices[device.guid] = device;
    }
    return res;
  }
}
