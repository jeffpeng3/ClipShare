package top.coclyun.clipshare

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import rikka.shizuku.Shizuku
import top.coclyun.clipshare.service.BackgroundService


class MainActivity : FlutterActivity(), Shizuku.OnRequestPermissionResultListener{
    private lateinit var commonChannel: MethodChannel;
    private lateinit var androidChannel: MethodChannel;
    private val requestShizukuCode = 5001
    private val requestOverlayResultCode = 5002


    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        @JvmStatic
        lateinit var engine: FlutterEngine
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Shizuku.addRequestPermissionResultListener(this);
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = flutterEngine
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        commonChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "common")
        androidChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "android")
        initCommonChannel()
        initAndroidChannel()
        // 创建 Intent 对象
        val serviceIntent = Intent(this, BackgroundService::class.java)

//        startService(serviceIntent);
        if (checkPermission(requestShizukuCode)) {
//            ClipboardListener.instance(this)!!.registerObserver(this)
            // 判断 Android 版本并启动服务
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
        }
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

    private fun initAndroidChannel() {
        androidChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                //检查悬浮窗权限
                "checkAlertWindowPermission" -> {
                    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                //授权悬浮窗权限
                "grantAlertWindowPermission" -> {
                    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
                        val intent = Intent(
                            ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        );
                        startActivityForResult(intent, requestOverlayResultCode);
                    }
                }
                //检查日志读取权限
                "checkReadLogsPermission" -> {
                    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
                        val res =
                            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_LOGS);
                        Log.d("checkReadLogsPermission", res.toString());
                        result.success(res == PackageManager.PERMISSION_GRANTED)
                    } else {
                        result.success(true)
                    }
                }
                //返回设备信息
                "getBaseInfo" -> {
                    val androId = Settings.System.getString(
                        contentResolver, Settings.System.ANDROID_ID
                    )

                    Log.d("getGuid", androId.toString());
                    Log.d("Build.MODEL", Build.MODEL);
                    result.success(
                        mapOf(
                            "guid" to androId,
                            "dev" to Build.MODEL
                        )
                    );
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
//        releaseWakeLock()
    }
}
