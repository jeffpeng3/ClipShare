import 'package:clipshare/entity/syncing_file.dart';
import 'package:refena_flutter/refena_flutter.dart';

final syncingFileProgressProvider =
    ChangeNotifierProvider((ref) => SyncingFileProgressNotifier());

class SyncingFileProgressNotifier extends ChangeNotifier {
  final _syncingFilesMap = <String, SyncingFile>{};

  void updateSyncingFile(SyncingFile syncingFile) {
    _syncingFilesMap[syncingFile.filePath] = syncingFile;
    notifyListeners();
  }

  void removeSyncingFile(String filePath) {
    _syncingFilesMap.remove(filePath);
    notifyListeners();
  }

  void clearAll() {
    _syncingFilesMap.clear();
    notifyListeners();
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
