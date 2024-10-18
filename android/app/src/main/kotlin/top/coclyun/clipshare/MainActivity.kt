package top.coclyun.clipshare

import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.PowerManager
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import top.coclyun.clipshare.broadcast.ScreenReceiver
import top.coclyun.clipshare.observer.SmsObserver
import top.coclyun.clipshare.service.HistoryFloatService
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream


class MainActivity : FlutterFragmentActivity() {
    private val requestOverlayResultCode = 5002
    private lateinit var screenReceiver: ScreenReceiver
    private val TAG: String = "MainActivity";
    private var smsObserver: SmsObserver? = null;

    companion object {
        lateinit var commonChannel: MethodChannel;
        lateinit var androidChannel: MethodChannel;
        lateinit var clipChannel: MethodChannel;
        lateinit var applicationContext: Context
        lateinit var pendingIntent: PendingIntent

        @JvmStatic
        var lockHistoryFloatLoc: Boolean = false

        var commonNotifyId = 2

        @JvmStatic
        val commonNotifyChannelId = "Common"

        /**
         * 发送通知
         */
        fun commonNotify(content: String) {
            // 构建通知
            val builder = NotificationCompat.Builder(applicationContext, commonNotifyChannelId)
                .setSmallIcon(R.drawable.launcher_icon)
                .setContentTitle("ClipShare")
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setFullScreenIntent(pendingIntent, true)
                // 点击通知后自动关闭
                .setAutoCancel(true)
                // 设置为公开可见通知
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
            }
            val notificationManager =
                applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
            // 发送通知
            notificationManager.notify(commonNotifyId++, builder.build())
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MainActivity.applicationContext = applicationContext
        MainActivity.pendingIntent = createPendingIntent()
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        commonChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "top.coclyun.clipshare/common"
        )
        androidChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "top.coclyun.clipshare/android"
        )
        clipChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "top.coclyun.clipshare/clip"
        )
        initCommonChannel()
        initAndroidChannel()
        createNotifyChannel();
    }

    private fun registerSmsObserver() {
        if (smsObserver != null) {
            unRegisterSmsObserver()
        }
        val handler = Handler()
        val observer = SmsObserver(this, handler)
        Log.d(TAG, "registerSmsObserver")
        smsObserver = observer
        contentResolver.registerContentObserver(Uri.parse("content://sms/"), true, observer)
    }

    private fun unRegisterSmsObserver() {
        if (smsObserver == null) return
        smsObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        smsObserver = null
        Log.d(TAG, "unRegisterSmsObserver")
    }

    private fun createNotifyChannel() {
        // 创建通知渠道（仅适用于 Android 8.0 及更高版本）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                commonNotifyChannelId,
                "普通通知",
                NotificationManager.IMPORTANCE_HIGH
            )
            val notificationManager =
                Companion.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * 检查通知权限
     */
    private fun checkNotification(): Boolean {
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        return notificationManager.areNotificationsEnabled()
    }

    /**
     * 请求通知权限
     */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            startActivity(intent)
        }
    }


    /**
     * 判断服务是否运行
     * @param context 上下文
     * @param serviceClass 服务类
     */
    private fun isServiceRunning(context: Context, serviceClass: Class<*>): Boolean {
        val activityManager = context.getSystemService(ACTIVITY_SERVICE) as ActivityManager

        // 获取运行中的服务列表
        for (service in activityManager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                // 如果找到匹配的服务类名，表示服务在运行
                return true
            }
        }
        // 未找到匹配的服务类名，表示服务未在运行
        return false
    }

    /**
     * 初始化平台channel
     */
    private fun initAndroidChannel() {
        // 注册广播接收器
        screenReceiver = ScreenReceiver(androidChannel)
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_ON)
        filter.addAction(Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenReceiver, filter)
        androidChannel.setMethodCallHandler { call, result ->
            var args: Map<String, Any> = mapOf()
            if (call.arguments is Map<*, *>) {
                args = call.arguments as Map<String, Any>
            }
            when (call.method) {
                //检查悬浮窗权限
                "checkAlertWindowPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                //授权悬浮窗权限
                "grantAlertWindowPermission" -> {
                    val intent = Intent(
                        ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    );
                    startActivityForResult(intent, requestOverlayResultCode);
                }
                //检查通知权限
                "checkNotification" -> {
                    result.success(checkNotification())
                }
                //授权通知权限
                "grantNotification" -> {
                    requestNotificationPermission()
                }
                //检查电池优化
                "checkIgnoreBattery" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                //请求忽略电池优化
                "requestIgnoreBattery" -> {
                    requestIgnoreBatteryOptimizations()
                }
                //将应用置于后台
                "moveToBg" -> {
                    moveTaskToBack(true)
                }
                //发送通知
                "sendNotify" -> {
                    val content = args["content"].toString();
                    commonNotify(content)
                    result.success(true);
                }
                //显示历史浮窗
                "showHistoryFloatWindow" -> {
                    if (!isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java))
                    }
                }
                //锁定悬浮窗位置
                "lockHistoryFloatLoc" -> {
                    lockHistoryFloatLoc = args["loc"] as Boolean
                }
                //关闭历史浮窗
                "closeHistoryFloatWindow" -> {
                    stopService(Intent(this, HistoryFloatService::class.java))
                }
                //提示
                "toast" -> {
                    val content = args["content"].toString();
                    Toast.makeText(this, content, Toast.LENGTH_LONG).show();
                    result.success(true);
                }
                //从content中复制文件到指定路径
                "copyFileFromUri" -> {
                    var savedPath: String? = null
                    try {
                        val content = args["content"].toString()
                        val uri = Uri.parse(content);
                        val documentFile = DocumentFile.fromSingleUri(this, uri)
                        val fileName = documentFile!!.name
                        savedPath = args["savedPath"].toString() + "/${fileName}";
                        val inputStream = contentResolver.openInputStream(uri)
                        if (inputStream == null) {
                            Log.e(TAG, "Failed to open input stream for URI: $content")
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val destFile = File(savedPath)
                        val outputStream: OutputStream = FileOutputStream(destFile)
                        val buffer = ByteArray(1024 * 10)
                        var length: Int
                        while (inputStream.read(buffer).also { length = it } > 0) {
                            outputStream.write(buffer, 0, length)
                        }
                        inputStream.close()
                        outputStream.close()
                    } catch (e: Exception) {
                        e.printStackTrace();
                        result.success(null)
                    }
                    result.success(savedPath)
                }
                //图片更新后通知媒体库扫描
                "notifyMediaScan" -> {
                    val imagePath = args["imagePath"].toString();
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(imagePath),
                        null
                    ) { path, uri ->
                        Log.i(TAG, "initAndroidChannel: MediaScanner Completed")
                    }
                }
                //开启短信监听
                "startSmsListen" -> {
                    registerSmsObserver()
                }
                //停止短信监听
                "stopSmsListen" -> {
                    unRegisterSmsObserver()
                }
            }
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.setData(Uri.parse("package:$packageName"))
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        var isIgnoring = false
        val powerManager: PowerManager? =
            getSystemService(Context.POWER_SERVICE) as PowerManager?
        if (powerManager != null) {
            isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return isIgnoring
    }

    /**
     * 初始化通用channel
     */
    private fun initCommonChannel() {
        commonChannel.setMethodCallHandler { call, result ->
            when (call.method) {
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestOverlayResultCode) {
            if (resultCode != Activity.RESULT_OK) {
                if (!Settings.canDrawOverlays(this)) {
                    Toast.makeText(
                        this,
                        "请授予悬浮窗权限，否则无法后台读取剪贴板！",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        if (!hasFocus) return
        Log.d("MainActivity", "onResume")
    }

    fun onSmsChanged(content: String) {
        androidChannel.invokeMethod(
            "onSmsChanged",
            mapOf("content" to content)
        )
    }

    override fun onRestart() {
        super.onRestart()
        Log.d("MainActivity", "onRestart")
    }

    override fun onStop() {
        super.onStop()
        Log.d("MainActivity", "onRestart")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "onDestroy")
        // 取消注册广播接收器
        unregisterReceiver(screenReceiver)
        //MainActivity被销毁时停止服务运行
        stopService(Intent(this, HistoryFloatService::class.java))
        unRegisterSmsObserver()
    }

    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, this::class.java)
        intent.putExtra("fromNotification", true)
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    }

}
