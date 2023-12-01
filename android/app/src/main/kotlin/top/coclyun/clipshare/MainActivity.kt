package top.coclyun.clipshare

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.BufferedReader
import java.io.InputStreamReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


class MainActivity : FlutterActivity(), ClipboardListener.ClipboardObserver {
    lateinit var channel: MethodChannel;
    lateinit var clipboard: ClipboardListener;
    private val REQUEST_OVERLAY = 5004
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ClipboardListener.instance(this)!!.registerObserver(this);
        if (!checkOverlayDisplayPermission()) {
            Toast.makeText(this, "请授予悬浮窗权限，否则无法后台读取剪贴板！", Toast.LENGTH_LONG)
                .show()
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        //调用Flutter端方法
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clip")

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if(requestCode == REQUEST_OVERLAY){
            if(resultCode!=Activity.RESULT_OK){
                Toast.makeText(this, "请授予悬浮窗权限，否则无法后台读取剪贴板！", Toast.LENGTH_LONG)
                    .show()
            }
        }
    }
    private fun checkOverlayDisplayPermission(): Boolean {
        // API23以后需要检查权限
        return if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                );
                startActivityForResult(intent, REQUEST_OVERLAY);
            }
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    override fun clipboardChanged(content: String, same: Boolean) {
        if (same) return
        channel.invokeMethod("setClipText", mapOf("text" to content))
    }


}
