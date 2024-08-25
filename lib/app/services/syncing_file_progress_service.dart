import 'package:clipshare/app/data/repository/entity/syncing_file.dart';
import 'package:get/get.dart';

class SyncingFileProgressService extends GetxService {
  final _syncingFilesMap = <String, SyncingFile>{}.obs;

  Future<SyncingFileProgressService> init() async {
    return this;
  }

  void updateSyncingFile(SyncingFile syncingFile) {
    _syncingFilesMap[syncingFile.filePath] = syncingFile;
  }

  void removeSyncingFile(String filePath) {
    _syncingFilesMap.remove(filePath);
  }

  void clearAll() {
    _syncingFilesMap.clear();
  }

  List<SyncingFile> getSyncingFiles() {
    final list = _syncingFilesMap.values.toList();
    list.sort((a, b) {
      if (a.state == b.state) {
        return a.fromDev.name.compareTo(b.fromDev.name);
      }
      return a.state.order.compareTo(b.state.order);
    });
    return list;
  }
}
