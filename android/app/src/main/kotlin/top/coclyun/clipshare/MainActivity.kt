package top.coclyun.clipshare

import android.R
import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.os.PowerManager
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import rikka.shizuku.Shizuku
import top.coclyun.clipshare.broadcast.ScreenReceiver
import top.coclyun.clipshare.service.BackgroundService


class MainActivity : FlutterActivity(), Shizuku.OnRequestPermissionResultListener {
    private lateinit var commonChannel: MethodChannel;
    private lateinit var androidChannel: MethodChannel;
    private val requestShizukuCode = 5001
    private val requestOverlayResultCode = 5002
    private var shizukuRunning = false;
    private lateinit var screenReceiver: ScreenReceiver;
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        @JvmStatic
        lateinit var engine: FlutterEngine
    }

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)

    }

    private fun initService() {
        Log.d("onCreate","initService")
        Shizuku.addRequestPermissionResultListener(this);
        val serviceRunning = isServiceRunning(this, BackgroundService::class.java)
        if (checkShizukuPermission(requestShizukuCode) && !serviceRunning) {
            Log.d("onCreate","start Service")
            // 创建 Intent 对象
            val serviceIntent = Intent(this, BackgroundService::class.java)
            // 判断 Android 版本并启动服务
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
        } else {
            androidChannel.invokeMethod("checkMustPermission", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = flutterEngine
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        commonChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "common")
        androidChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "android")
        initCommonChannel()
        initAndroidChannel()
        val fromNotification = intent.getBooleanExtra("fromNotification", false)
        if (fromNotification) {
            notify("fromNotification")
            return
        }
        initService()
    }

    private fun notify(content: String) {
        val updatedBuilder: NotificationCompat.Builder =
            NotificationCompat.Builder(this, BackgroundService.notifyChannelId)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setSmallIcon(R.drawable.btn_star_big_on)
                .setOngoing(true)
                .setSound(null)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
                .setContentText(content)
        val manger = getSystemService(
            NOTIFICATION_SERVICE
        ) as NotificationManager
        // 发送通知
        manger.notify(BackgroundService.notificationId, updatedBuilder.build())
    }

    override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
        val granted = grantResult == PackageManager.PERMISSION_GRANTED
        // Do stuff based on the result and the request code
        if (granted) {
            when (requestCode) {
                requestShizukuCode -> {
                    Toast.makeText(this, "shizuku 已授权", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun checkShizukuPermission(code: Int): Boolean {
        if (Shizuku.isPreV11()) {
            Toast.makeText(this, "Pre-v11 is unsupported", Toast.LENGTH_LONG).show()
            return false
        }
        try {
            return if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                // Granted
                true
            } else if (Shizuku.shouldShowRequestPermissionRationale()) {
                // Users choose "Deny and don't ask again"
                Toast.makeText(this, "shouldShowRequestPermissionRationale", Toast.LENGTH_LONG)
                    .show()
                false
            } else {
                // Request the permission
                Toast.makeText(this, "else", Toast.LENGTH_LONG).show()
                Shizuku.requestPermission(code)
                false
            }
        } catch (e: Exception) {
            return false;
        }
    }

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
                //返回设备信息
                "getBaseInfo" -> {
                    val androId = Settings.System.getString(
                        contentResolver, Settings.System.ANDROID_ID
                    )
                    result.success(
                        mapOf(
                            "guid" to androId,
                            "dev" to Build.MODEL,
                            "type" to "Android"
                        )
                    );
                }
                //将应用置于后台
                "moveToBg" -> {
                    moveTaskToBack(true)
                }
                //发送通知
                "sendNotify" -> {
                    val content = args["content"].toString();
                    notify(content)
                    result.success(true);
                }

                "toast" -> {
                    val content = args["content"].toString();
                    Toast.makeText(this, content, Toast.LENGTH_LONG).show();
                    result.success(true);
                }
            }
        }
    }

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


    private fun acquireWakeLock() {
        Log.d("wakeLock", "acquireWakeLock")
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "YourTag:WakeLockTag")
        wakeLock?.acquire()
    }

    private fun releaseWakeLock() {
        wakeLock?.release()
        wakeLock = null
        Log.d("wakeLock", "releaseWakeLock")
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
//        releaseWakeLock()
    }
}
