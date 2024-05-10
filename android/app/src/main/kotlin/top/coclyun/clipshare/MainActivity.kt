package top.coclyun.clipshare

import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import rikka.shizuku.Shizuku
import top.coclyun.clipshare.broadcast.ScreenReceiver
import top.coclyun.clipshare.service.ForegroundService
import top.coclyun.clipshare.service.HistoryFloatService


class MainActivity : FlutterFragmentActivity(), Shizuku.OnRequestPermissionResultListener {
    private val requestShizukuCode = 5001
    private val requestOverlayResultCode = 5002
    private lateinit var screenReceiver: ScreenReceiver
    private val TAG: String = "MainActivity";

    companion object {
        lateinit var commonChannel: MethodChannel;
        lateinit var androidChannel: MethodChannel;
        lateinit var clipChannel: MethodChannel;
        lateinit var applicationContext: Context
        lateinit var pendingIntent: PendingIntent

        @JvmStatic
        var lockHistoryFloatLoc: Boolean = false

        @JvmStatic
        var innerCopy: Boolean = false

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
                builder.setBadgeIconType(R.drawable.launcher_icon)
            }
            val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
            // 发送通知
            notificationManager.notify(commonNotifyId++, builder.build())
        }
    }

    private fun initService() {
        Log.d("onCreate", "initService")
        Shizuku.addRequestPermissionResultListener(this);
        val serviceRunning = isServiceRunning(this, ForegroundService::class.java)
        if (serviceRunning) {
//            stopService(Intent(this, ForegroundService::class.java))
            return;
        }
        if (checkShizukuPermission(requestShizukuCode)) {
            Log.d("onCreate", "start Service")
            // 创建 Intent 对象
            val serviceIntent = Intent(this, ForegroundService::class.java)
            // 判断 Android 版本并启动服务
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
        } else {
            androidChannel.invokeMethod("checkMustPermission", null)
        }
        createNotifyChannel();
    }

    private fun createNotifyChannel() {
        // 创建通知渠道（仅适用于 Android 8.0 及更高版本）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(commonNotifyChannelId, "普通通知", NotificationManager.IMPORTANCE_HIGH)
            val notificationManager = Companion.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
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
        initClipChannel()
        initAndroidChannel()
        initService()
    }


    override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
        val granted = grantResult == PackageManager.PERMISSION_GRANTED
        // Do stuff based on the result and the request code
        if (granted) {
            when (requestCode) {
                requestShizukuCode -> {
                    Toast.makeText(this, "Shizuku 已授权", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    /**
     * 检查shizuku权限
     * @param code 权限代码
     */
    private fun checkShizukuPermission(code: Int): Boolean {
        if (Shizuku.isPreV11()) {
            Toast.makeText(this, "Pre-v11 is unsupported", Toast.LENGTH_LONG).show()
            Log.d(TAG, "Pre-v11 is unsupported")
            return false
        }
        try {
            return if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                // Granted
                true
            } else if (Shizuku.shouldShowRequestPermissionRationale()) {
                // Users choose "Deny and don't ask again"
                Log.d(TAG, "shouldShowRequestPermissionRationale")
                false
            } else {
                // Request the permission
                Log.d(TAG, "else")
                false
            }
        } catch (e: Exception) {
            return false;
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
     * 初始化剪贴板channel
     */
    private fun initClipChannel() {
        clipChannel.setMethodCallHandler { call, result ->
            var args: Map<String, Any> = mapOf()
            if (call.arguments is Map<*, *>) {
                args = call.arguments as Map<String, Any>
            }
            when (call.method) {
                "copy" -> {
                    try {
                        innerCopy = true;
                        val type = args["type"].toString()
                        val content = args["content"].toString()
                        // 获取剪贴板管理器
                        val clipboardManager = ContextCompat.getSystemService(
                                applicationContext,
                                ClipboardManager::class.java
                        ) as ClipboardManager
                        when (type) {
                            "Text" -> {
                                // 创建一个剪贴板数据
                                val clipData = ClipData.newPlainText("text", content)
                                // 将数据放入剪贴板
                                clipboardManager.setPrimaryClip(clipData)
                                result.success(true)
                            }

                            "Image" -> {
                                val uri =
                                        Uri.parse("content://top.coclyun.clipshare.FileProvider/$content")
                                val clipData =
                                        ClipData.newUri(applicationContext.contentResolver, "image", uri)
                                // 将数据放入剪贴板
                                clipboardManager.setPrimaryClip(clipData)
                                result.success(true)
                            }
                        }
                        result.success(false)
                    } catch (e: Exception) {
                        innerCopy = false;
                        result.success(false)
                    }

                }
            }
        }
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
                //检查shizuku权限
                "checkShizukuPermission" -> {
                    result.success(checkShizukuPermission(requestShizukuCode))
                }
                //授权shizuku权限
                "grantShizukuPermission" -> {
                    Shizuku.requestPermission(requestShizukuCode)
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
                //启动服务
                "startService" -> {
                    initService()
                }
                //提示
                "toast" -> {
                    val content = args["content"].toString();
                    Toast.makeText(this, content, Toast.LENGTH_LONG).show();
                    result.success(true);
                }
                //图片更新后通知媒体库扫描
                "notifyMediaScan" -> {
                    val imagePath = args["imagePath"].toString();
                    MediaScannerConnection.scanFile(applicationContext, arrayOf(imagePath), null) { path, uri ->
                        // 扫描完成后的操作，可以在这里添加你的逻辑
                        Log.i(TAG, "initAndroidChannel: MediaScanner Completed")
                    }
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
            isIgnoring = powerManager.isIgnoringBatteryOptimizations(getPackageName())
        }
        return isIgnoring
    }

    /**
     * 初始化通用channel
     */
    private fun initCommonChannel() {
        commonChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                //返回设备信息
                "getBaseInfo" -> {
                    val androId = Settings.System.getString(
                            contentResolver, Settings.System.ANDROID_ID
                    )
                    result.success(
                            mapOf(
                                    "guid" to androId,
                                    "dev" to Build.MODEL,
                                    "type" to "Android",
                            )
                    );
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestOverlayResultCode) {
            if (resultCode != Activity.RESULT_OK) {
                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                    Toast.makeText(
                            this,
                            "请授予悬浮窗权限，否则无法后台读取剪贴板！",
                            Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
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
        Shizuku.removeRequestPermissionResultListener(this);
        Log.d("MainActivity", "onDestroy")
        // 取消注册广播接收器
        unregisterReceiver(screenReceiver)
        //MainActivity被销毁时停止服务运行
        stopService(Intent(this, ForegroundService::class.java))
        stopService(Intent(this, HistoryFloatService::class.java))
    }

    fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, this::class.java)
        intent.putExtra("fromNotification", true)
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    }
}
