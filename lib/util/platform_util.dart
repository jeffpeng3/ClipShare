import 'dart:io';

class PlatformUtil {
  static bool isWindows() {
    return Platform.isWindows;
  }

  static bool isLinux() {
    return Platform.isLinux;
  }

  static bool isMacOS() {
    return Platform.isMacOS;
  }

  static bool isFuchsia() {
    return Platform.isFuchsia;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isMobile() {
    return isIOS() || isAndroid();
  }

  static bool isPC() {
    return isMacOS() || isLinux() || isLinux() || isWindows();
  }
}
