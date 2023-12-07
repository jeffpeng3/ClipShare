package top.coclyun.clipshare.service

import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.SystemServiceHelper
import top.coclyun.clipshare.ClipboardListener
import top.coclyun.clipshare.MainActivity


class BackgroundService : Service(), ClipboardListener.ClipboardObserver {

    private val notificationId = 1
    private val notifyChannelId = "BackgroundService"
    private lateinit var clipChannel: MethodChannel

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("backgroundService","onStartCommand")
        clipChannel = MethodChannel(MainActivity.engine.dartExecutor.binaryMessenger, "clip")
        // 在这里执行服务的逻辑
        ClipboardListener.instance(this)!!.registerObserver(this)
        // 在 Android 8.0 及以上版本，需要创建通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        // 创建并显示通知
        val notification = buildNotification()
        val manger = getSystemService(
            NOTIFICATION_SERVICE
        ) as NotificationManager
//        manger.notify(notificationId, notification)
//        startForeground(notificationId, notification)
        Log.d("notify", "startForeground")
        return START_STICKY
    }


    override fun clipboardChanged(content: String, same: Boolean) {
        Log.d("clipboardChanged", "is same $same")
        if (same) return
        clipChannel.invokeMethod("setClipText", mapOf("text" to content))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name: CharSequence = "MyServiceChannel"
            val description = "Channel for MyService"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(notifyChannelId, name, importance)
            channel.description = description
            val notificationManager = getSystemService(
                NOTIFICATION_SERVICE
            ) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d("notify", "createNotificationChannel")
        }
    }

    private fun buildNotification(): Notification {
        // 创建通知
        val builder: Notification.Builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, notifyChannelId)
        } else {
            Notification.Builder(this)
        }

        // 设置通知的标题、内容等
        builder.setContentTitle("剪贴板同步")
        builder.setContentText("剪贴板监听服务正在运行")
        builder.setSmallIcon(R.drawable.btn_star_big_on)
        Log.d("notify", "buildNotification")
        return builder.build()
    }

    override fun onDestroy() {
        super.onDestroy()
        ClipboardListener.instance(this)!!.removeObserver(this)
    }

    override fun onBind(intent: Intent): IBinder? {
        return null;
    }
}