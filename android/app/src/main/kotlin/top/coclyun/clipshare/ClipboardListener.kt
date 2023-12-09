package top.coclyun.clipshare

import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.util.Log
import android.widget.Toast
import androidx.core.content.ContextCompat
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


open class ClipboardListener(context: Context) {
    private val TAG: String = "ClipboardListener";

    interface ClipboardObserver {
        fun clipboardChanged(content: String, same: Boolean)
    }

    private val observers = HashSet<ClipboardObserver>()

    fun registerObserver(observer: ClipboardObserver): ClipboardListener {
        observers.add(observer)
        return this
    }

    fun removeObserver(observer: ClipboardObserver): ClipboardListener {
        observers.remove(observer)
        return this
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
            line?.let { Log.d("read_logs", it) }
            if (line!!.contains(BuildConfig.APPLICATION_ID)) {
                context.startActivity(ClipboardFloatActivity.getIntent(context))
            }
        }
        Log.d("read_logs", "finished")
    }

    fun onClipboardChanged() {
        try {
            Log.d("clipboardChanged", "listener")
            val item = cm!!.primaryClip!!.getItemAt(0)
            val content = item.coerceToText(context).toString()
            val isSame = content == lastContent;
            lastContent = content
            for (observer in observers) {
                observer.clipboardChanged(content, isSame)
            }
        } catch (e: Exception) {

            Toast.makeText(context, "剪贴板异常: ${e.message}", Toast.LENGTH_LONG).show()
            //Probably clipboard was not text
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