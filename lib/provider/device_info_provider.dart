import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/devices.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:refena_flutter/refena_flutter.dart';

final deviceInfoProvider = NotifierProvider<DeviceInfoProvider, Devices>((ref) {
  return DeviceInfoProvider();
});

class DeviceInfoProvider extends Notifier<Devices> {
  final DeviceDao _deviceDao = DBUtil.inst.deviceDao;

  @override
  Devices init() {
    _deviceDao.getAllDevices(App.userId).then((lst) {
      state = Devices(lst);
    });
    return Devices([]);
  }

  List<Device> getPairedList() {
    return state.pairedList;
  }

  Future<bool> _addOrUpdate(Device device) async {
    var v = await _deviceDao.getById(device.guid, App.userId);
    if (v == null) {
      return await _deviceDao.add(device)>0;
    } else {
      return await _deviceDao.updateDevice(device)>0;
    }
  }

  Future<bool> addOrUpdate(Device device) async {
    var res = await _addOrUpdate(device);
    if(res) {
      state = state.copyWith(device);
    }
    return res;
  }
}
