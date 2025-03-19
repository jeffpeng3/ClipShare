import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class WindowControlService extends GetxService {
  final maxWindow = false.obs;
  final closeBtnHovered = false.obs;
  final maximizable = false.obs;
  final minimizable = false.obs;
  final closeable = true.obs;
  final resizable = false.obs;
  final alwaysOnTop = false.obs;

  ///初始化窗体尺寸信息
  Future<WindowControlService> initWindows() async {
    await windowManager.isMaximized().then((maximized) {
      maxWindow.value = maximized;
    });
    await windowManager.isClosable().then((closeable) {
      this.closeable.value = closeable;
    });
    await windowManager.isMinimizable().then((minimizable) {
      this.minimizable.value = minimizable;
    });
    await windowManager.isMaximizable().then((maximizable) {
      this.maximizable.value = maximizable;
    });
    await windowManager.isResizable().then((resizable) {
      this.resizable.value = resizable;
    });
    return this;
  }

  Future<void> setMinimizable(bool minimizable) async {
    await windowManager.setMinimizable(minimizable);
    this.minimizable.value = minimizable;
  }

  Future<void> setMaximizable(bool maximizable) async {
    await windowManager.setMaximizable(maximizable);
    this.maximizable.value = maximizable;
  }

  Future<void> setCloseable(bool closeable) async {
    await windowManager.setClosable(closeable);
    this.closeable.value = closeable;
  }

  Future<void> setResizable(bool resizable) async {
    await windowManager.setResizable(resizable);
    this.resizable.value = resizable;
  }

  Future<void> maximize() async {
    await windowManager.maximize();
    maxWindow.value = true;
  }

  Future<void> minimize() async {
    await windowManager.minimize();
    maxWindow.value = false;
  }

  Future<void> restore() async {
    await windowManager.restore();
    maxWindow.value = false;
  }
  Future<void> setAlwaysOnTop(bool top) async {
    await windowManager.setAlwaysOnTop(top);
    this.alwaysOnTop.value = false;
  }
}
