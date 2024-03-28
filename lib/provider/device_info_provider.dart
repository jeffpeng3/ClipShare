import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/devices.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:refena_flutter/refena_flutter.dart';

final class DeviceInfoProvider extends Notifier<Devices> {
  final DeviceDao _deviceDao = DBUtil.inst.deviceDao;
  static Devices? _devices;
  static final NotifierProvider<DeviceInfoProvider, Devices> inst =
      NotifierProvider<DeviceInfoProvider, Devices>((ref) {
    return DeviceInfoProvider();
  });

  @override
  Devices init() {
    if (_devices == null) {
      _deviceDao.getAllDevices(App.userId).then((lst) {
        _devices =state = Devices(lst);
      });
    }
    return _devices ?? Devices([]);
  }

  List<Device> getPairedList() {
    return state.pairedList;
  }

  Future<bool> _addOrUpdate(Device device) async {
    var v = await _deviceDao.getById(device.guid, App.userId);
    if (v == null) {
      return await _deviceDao.add(device) > 0;
    } else {
      return await _deviceDao.updateDevice(device) > 0;
    }
  }

  Future<bool> addOrUpdate(Device device) async {
    var res = await _addOrUpdate(device);
    if (res) {
      _devices = state = state.copyWith(device);
    }
    return res;
  }
}
