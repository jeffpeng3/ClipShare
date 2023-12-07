// IClipboardService.aidl
package top.coclyun.clipshare;
import top.coclyun.clipshare.INoArgsCallBack;
interface IClipboardService {
    void destroy() = 16777114; // Destroy method defined by Shizuku server
    void readLogs(in INoArgsCallBack callback) = 1;
}