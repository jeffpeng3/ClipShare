import 'package:clipshare/entity/tables/device.dart';
import 'package:floor/floor.dart';

@dao
abstract class DeviceDao {
  ///获取所有设备
  @Query("select * from device where uid = :uid")
  Future<List<Device>> getAllDevices(String uid);

  ///根据设备id获取设备信息
  @Query("select * from device where guid = :guid and uid = :uid")
  Future<Device?> getById(String guid, String uid);

  ///添加一个设备
  @insert
  Future<int> add(Device dev);

  ///更新设备信息
  @update
  Future<int> updateDevice(Device dev);

  ///删除设备（逻辑删？todo）
  @Query("delete from device where guid = :guid and uid = :uid")
  Future<int?> remove(String guid, String uid);
}
