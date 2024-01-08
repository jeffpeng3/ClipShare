package top.coclyun.clipshare.service

import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Message
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import top.coclyun.clipshare.BuildConfig
import top.coclyun.clipshare.ClipboardFloatActivity
import top.coclyun.clipshare.ClipboardListener
import top.coclyun.clipshare.MainActivity
import java.io.BufferedReader
import java.io.InputStreamReader
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


class BackgroundService : Service(),
    ClipboardListener.ClipboardObserver {
    companion object {
        @JvmStatic
        val notificationId = 1

        @JvmStatic
        val notifyChannelId = "BackgroundService"
    }

    class MyHandler(context: Context) : Handler() {
        private val mOuter: WeakReference<Context> = WeakReference<Context>(context)

        override fun handleMessage(msg: Message) {

            Log.d("read_logs", "on Msg")
            mOuter.get().let {
                Log.d("read_logs", it.toString())
                it?.startActivity(ClipboardFloatActivity.getIntent(it))
            }
        }
    }

    //mHandler用于弱引用和主线程更新UI，为什么一定要这样搞呢，简单地说就是不这样就会报错、会内存泄漏。
    private var mHandler = MyHandler(this)
    private lateinit var clipChannel: MethodChannel
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("backgroundService", "onStartCommand")
        // 在这里执行服务的逻辑
        ClipboardListener.instance(this)!!.registerObserver(this)
        clipChannel = MethodChannel(MainActivity.engine.dartExecutor.binaryMessenger, "clip")
        // 在 Android 8.0 及以上版本，需要创建通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        // 创建并显示通知
        val notification = buildNotification()

        val manger = getSystemService(
            NOTIFICATION_SERVICE
        ) as NotificationManager
        manger.notify(notificationId, notification)
        startForeground(notificationId, notification)
        Log.d("notify", "startForeground")
        readLogByShizuku()
        return START_STICKY
    }

    private fun readLogByShizuku() {
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
                        line?.let { Log.d("read_logs", "self log") }
                        mHandler.sendMessage(Message())
                    }
                }
                notify("日志服务异常停止：")
                Log.d("read_logs", "finished")
            } catch (e: Exception) {
                notify("shizuku服务异常停止：" + e.message)
                e.printStackTrace()
                e.message?.let { Log.e("read_logs", it) }
            }
        }
        t.isDaemon = true
        t.start()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name: CharSequence = "ClipShareMain"
            val description = "ClipShareMainService"
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
        builder.setContentTitle("ClipShare")
            .setSmallIcon(R.drawable.btn_star_big_on)
            .setOngoing(true)
            .setSound(null)
            .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
            .setContentText("ClipShare 正在运行")
        Log.d("notify", "buildNotification")
        return builder.build()
    }

    override fun onDestroy() {
        super.onDestroy()
        ClipboardListener.instance(this)!!.removeObserver(this)
    }

    override fun clipboardChanged(content: String, same: Boolean) {
        Log.d("clipboardChanged", "is same $same")
        if (same) return
        clipChannel.invokeMethod("setClipText", mapOf("text" to content))
        notify(content);
    }

    private fun createPendingIntent(): PendingIntent? {
        val intent = Intent(this, MainActivity::class.java)
        intent.putExtra("fromNotification", true)
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    }

    private fun notify(content: String) {
        val updatedBuilder: NotificationCompat.Builder =
            NotificationCompat.Builder(this, notifyChannelId)
                .setSmallIcon(R.drawable.btn_star_big_on)
                .setContentTitle("ClipShare")
                .setOngoing(true)
                .setSound(null)
                .setContentIntent(createPendingIntent())
                .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        val manger = getSystemService(
            NOTIFICATION_SERVICE
        ) as NotificationManager
        // 更新通知
        manger.notify(notificationId, updatedBuilder.build())
    }

    override fun onBind(intent: Intent): IBinder? {
        return null;
    }
}