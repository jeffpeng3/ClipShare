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

    private lateinit var screenReceiver: ScreenReceiver;
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        @JvmStatic
        lateinit var engine: FlutterEngine
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Shizuku.addRequestPermissionResultListener(this);
        notify("onCreate")
        // 注册广播接收器

//        acquireWakeLock()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        notify("configureFlutterEngine")
        engine = flutterEngine
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        commonChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "common")
        androidChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "android")
        initCommonChannel()
        initAndroidChannel()

        val serviceRunning = isServiceRunning(this, BackgroundService::class.java)
        if (checkPermission(requestShizukuCode) && !serviceRunning) {
            // 创建 Intent 对象
            val serviceIntent = Intent(this, BackgroundService::class.java)
            // 判断 Android 版本并启动服务
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
        }
    }

    private fun notify(content: String) {
        val updatedBuilder: NotificationCompat.Builder =
            NotificationCompat.Builder(this, BackgroundService.notifyChannelId)
                .setSmallIcon(R.drawable.btn_star_big_on)
                .setContentTitle("剪贴板更新")
                .setOngoing(true)
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        val manger = getSystemService(
            NOTIFICATION_SERVICE
        ) as NotificationManager
        // 更新通知
        manger.notify(BackgroundService.notificationId, updatedBuilder.build())
    }

    override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
        val granted = grantResult == PackageManager.PERMISSION_GRANTED
        // Do stuff based on the result and the request code
        if (granted) {
            when (requestCode) {
                requestShizukuCode -> {
                    Toast.makeText(this, "shizuku granted", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun checkPermission(code: Int): Boolean {
        if (Shizuku.isPreV11()) {
            Toast.makeText(this, "Pre-v11 is unsupported", Toast.LENGTH_LONG).show()
            return false
        }
        return if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
            // Granted
            true
        } else if (Shizuku.shouldShowRequestPermissionRationale()) {
            // Users choose "Deny and don't ask again"
            false
        } else {
            // Request the permission
            Shizuku.requestPermission(code)
            false
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
                //发送通知
//                "sendNotify" -> {
//                    var content = call.arguments['content'].toString();
//                    notify(content);
//                    result.success(true);
//                }
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
        notify("onRestart")
    }

    override fun onStop() {
        super.onStop()
        Log.d("MainActivity", "onRestart")
        notify("onStop")
    }

    override fun onDestroy() {
        super.onDestroy()
        Shizuku.removeRequestPermissionResultListener(this);
        Log.d("MainActivity", "onDestroy")
        notify("onDestroy")
        // 取消注册广播接收器
        unregisterReceiver(screenReceiver)
//        releaseWakeLock()
    }

    override fun onBackPressed() {
        moveTaskToBack(true)
    }
}
