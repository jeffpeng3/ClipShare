package top.coclyun.clipshare.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Message
import android.util.Log
import androidx.core.app.NotificationCompat
import rikka.shizuku.Shizuku
import top.coclyun.clipshare.BuildConfig
import top.coclyun.clipshare.ClipboardFocusActivity
import top.coclyun.clipshare.ClipboardListener
import top.coclyun.clipshare.MainActivity
import top.coclyun.clipshare.R
import top.coclyun.clipshare.enums.ContentType
import java.io.BufferedReader
import java.io.InputStreamReader
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


class ForegroundService : Service(),
        ClipboardListener.ClipboardObserver {
    companion object {
        @JvmStatic
        val foregroundServiceNotificationId = 1

        @JvmStatic
        val foregroundServiceNotifyChannelId = "ForegroundService"
    }

    class MyHandler(context: Context) : Handler() {
        private val mOuter: WeakReference<Context> = WeakReference<Context>(context)

        override fun handleMessage(msg: Message) {

            Log.d("read_logs", "on Msg")
            mOuter.get().let {
                Log.d("read_logs", it.toString())
                it?.startActivity(ClipboardFocusActivity.getIntent(it))
            }
        }
    }

    //mHandler用于弱引用和主线程更新UI，为什么一定要这样搞呢，简单地说就是不这样就会报错、会内存泄漏。
    private var mHandler = MyHandler(this)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("ForegroundService", "onStartCommand")
        // 在这里执行服务的逻辑
        ClipboardListener.instance(this)!!.registerObserver(this)
        createNotify();
        readLogByShizuku()
        return START_NOT_STICKY
    }

    private fun createNotify() {
        // 在 Android 8.0 及以上版本，需要创建通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        // 创建并显示通知
        val notification = buildNotification()

        val manger = getSystemService(
                NOTIFICATION_SERVICE
        ) as NotificationManager
        manger.notify(foregroundServiceNotificationId, notification)
        startForeground(foregroundServiceNotificationId, notification)
        notifyForeground("服务正在运行")
    }

    private fun readLogByShizuku() {
        //Android 10以下才需要shizuku
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            return
        }
        val timeStamp: String =
                SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
        val cmdStrArr = arrayOf(
                "logcat",
                "-T",
                timeStamp,
                "ClipboardService:E",
                "*:S"
        )
        val process = Shizuku.newProcess(cmdStrArr, null, null)
        val t = Thread {
            try {
                Log.d("read_logs", "start")
                val bufferedReader = BufferedReader(InputStreamReader(process.inputStream))
                var line: String?
                while (bufferedReader.readLine().also { line = it } != null) {
                    line?.let { Log.d("read_logs", it) }
                    if (line!!.contains(BuildConfig.APPLICATION_ID)) {
                        if (MainActivity.innerCopy) {
                            Log.d("clipboardChanged", "is innerCopy")
                            MainActivity.innerCopy = false
                        } else {
                            line?.let { Log.d("read_logs", "self log") }
                            mHandler.sendMessage(Message())
                        }
                    }
                }
                notifyForeground("日志读取异常停止")
                MainActivity.commonNotify("日志读取异常停止")
                Log.d("read_logs", "finished")
            } catch (e: Exception) {
                notifyForeground("Shizuku服务异常停止：" + e.message)
                MainActivity.commonNotify("Shizuku服务异常停止：" + e.message)
                e.printStackTrace()
                e.message?.let { Log.e("read_logs", it) }
            }
        }
        t.isDaemon = true
        t.start()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name: CharSequence = "前台通知"
            val description = "前台通知服务，告知服务状态允许"
            val importance = NotificationManager.IMPORTANCE_MIN
            val channel = NotificationChannel(foregroundServiceNotifyChannelId, name, importance)
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
            Notification.Builder(this, foregroundServiceNotifyChannelId)
        } else {
            Notification.Builder(this)
        }

        // 设置通知的标题、内容等
        builder.setContentTitle("ClipShare")
                .setSmallIcon(R.mipmap.launcher_icon)
                .setOngoing(true)
                .setSound(null)
                .setContentIntent(MainActivity.pendingIntent)
//            .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
                .setContentText("ClipShare 正在运行")
        Log.d("notify", "buildNotification")
        return builder.build()
    }

    override fun onDestroy() {
        super.onDestroy()
        ClipboardListener.instance(this)!!.removeObserver(this)
    }

    override fun clipboardChanged(type: ContentType, content: String, same: Boolean) {
//        Log.d("clipboardChanged", "is same $same")
//        if (same) return
        if(MainActivity.innerCopy)return;
        MainActivity.clipChannel.invokeMethod(
                "onClipboardChanged",
                mapOf("content" to content, "type" to type.name)
        )
    }

    private fun notifyForeground(content: String) {
        val updatedBuilder: NotificationCompat.Builder =
                NotificationCompat.Builder(this, foregroundServiceNotifyChannelId)
                        .setSmallIcon(R.drawable.launcher_icon)
                        .setContentTitle("ClipShare")
                        .setOngoing(true)
                        .setSound(null)
                        .setContentIntent(MainActivity.pendingIntent)
                        .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
                        .setContentText(content)
        val manger = getSystemService(
                NOTIFICATION_SERVICE
        ) as NotificationManager
        // 更新通知
        manger.notify(foregroundServiceNotificationId, updatedBuilder.build())
    }

    override fun onBind(intent: Intent): IBinder? {
        return null;
    }
}