import 'dart:io';

extension PlatformExt on Platform {
  static bool get isMobile {
    return Platform.isIOS || Platform.isAndroid;
  }

  static bool get isDesktop {
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }
}
