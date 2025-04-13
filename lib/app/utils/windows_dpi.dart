import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef GetDpiForWindowNative = Int32 Function(IntPtr hwnd);
typedef GetDpiForWindow = int Function(int hwnd);

final user32 = DynamicLibrary.open('user32.dll');

final getDpiForWindow = user32.lookupFunction<GetDpiForWindowNative, GetDpiForWindow>(
  'GetDpiForWindow',
);

int getWindowsScaling() {
  // 获取主窗口句柄（需要从Windows原生代码传递）
  // 或者可以使用 GetDpiForMonitor 或 GetDpiForSystem
  final dpi = getDpiForWindow(0); // 0表示系统DPI
  return (dpi / 96).round(); // 96是100%缩放的标准DPI
}