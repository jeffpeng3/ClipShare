package top.coclyun.clipshare

import android.app.Activity
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.InputStreamReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


class ClipboardListener(context: Context) {
    interface ClipboardObserver {
        fun clipboardChanged(content: String, same: Boolean)
    }

    private val READ_LOGS = "android.permission.READ_LOGS"
    private val observers = HashSet<ClipboardObserver>()

    fun registerObserver(observer: ClipboardObserver): ClipboardListener {
        observers.add(observer)
        return this
    }

    fun removeObserver(observer: ClipboardObserver) {
        observers.remove(observer)
    }

    private var context: Context;
    private var lastContent: String? = null;
    private var cm: ClipboardManager? = null;

    init {
        this.context = context
        Handler(Looper.getMainLooper()).post {
            cm = ContextCompat.getSystemService(
                context,
                ClipboardManager::class.java
            )
            cm!!.addPrimaryClipChangedListener(this::onClipboardChanged)
        }
        val hasPerm = ContextCompat.checkSelfPermission(
            context,
            READ_LOGS
        ) == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P && hasPerm) {
            Thread {
                readLog()
            }.start()
        }
    }

    fun onClipboardChanged() {
        try {
            val item = cm!!.primaryClip!!.getItemAt(0)
            val content = item.coerceToText(context).toString()
            val isSame = content == lastContent;
            lastContent = content
            for (observer in observers) {
                observer.clipboardChanged(content, isSame)
            }
        } catch (e: Exception) {
            //Probably clipboard was not text
        }
    }


    private fun readLog() {
        val timeStamp: String =
            SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
        val cmdStrArr = arrayOf(
            "logcat",
            "-T",
            timeStamp,
            "ClipboardService:E",
            "*:S"
        )
        val process = Runtime.getRuntime().exec(cmdStrArr)
        val bufferedReader = BufferedReader(InputStreamReader(process.inputStream))
        var line: String?
        while (bufferedReader.readLine().also { line = it } != null) {
            if (line!!.contains(BuildConfig.APPLICATION_ID)) {
                (context as Activity).runOnUiThread {
//                    channel.invokeMethod("writeLog", mapOf("log" to line))
                    context.startActivity(ClipboardFloatActivity.getIntent(context))
                }
            }
        }
    }

    @Suppress("deprecation")
    fun setText(text: String) {
        if (cm != null) {
            lastContent = text
            cm!!.text = text
        }
    }

    companion object {
        private var _instance: ClipboardListener? = null

        @JvmStatic
        fun instance(context: Context): ClipboardListener? {
            if (_instance == null) {
                _instance = ClipboardListener(context)
                // FIXME: The _instance we return won't be completely initialized yet since initialization happens on a new thread (why?)
            }
            return _instance
        }
    }


}