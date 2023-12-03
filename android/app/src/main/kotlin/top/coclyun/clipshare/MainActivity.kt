package top.coclyun.clipshare

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity(), ClipboardListener.ClipboardObserver {
    private lateinit var commonChannel: MethodChannel;
    private lateinit var clipChannel: MethodChannel;
    private lateinit var androidChannel: MethodChannel;
    lateinit var clipboard: ClipboardListener;
    private val requestDeviceResultCode = 5001
    private val requestOverlayResultCode = 5002
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ClipboardListener.instance(this)!!.registerObserver(this);
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        //设置channel
        clipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clip")
        commonChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "common")
        androidChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "android")
        initCommonChannel()
        initAndroidChannel()
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


    override fun clipboardChanged(content: String, same: Boolean) {
        Log.d("clipboardChanged", "is same $same")
        if (same) return
        clipChannel.invokeMethod("setClipText", mapOf("text" to content))
    }


}
