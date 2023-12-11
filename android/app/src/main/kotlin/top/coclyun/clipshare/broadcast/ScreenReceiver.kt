package top.coclyun.clipshare.broadcast

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class ScreenReceiver internal constructor(private var androidChannel: MethodChannel) :
    BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_SCREEN_ON == intent.action) {
            // 屏幕已打开
            androidChannel.invokeMethod("onScreenOpened", null)
            // 在这里执行你的逻辑
        } else if (Intent.ACTION_SCREEN_OFF == intent.action) {
            // 屏幕已关闭
            androidChannel.invokeMethod("onScreenClosed", null)
            // 在这里执行你的逻辑
        }
    }
}