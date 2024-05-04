package top.coclyun.clipshare

import android.content.ClipboardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import top.coclyun.clipshare.enums.ContentType
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


open class ClipboardListener(context: Context) {
    private val TAG: String = "ClipboardListener";

    interface ClipboardObserver {
        fun clipboardChanged(type: ContentType, content: String, same: Boolean)
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
    private var lastType: ContentType? = null;
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

    fun onClipboardChanged() {
        try {
            Log.d("clipboardChanged", "listener")
            val item = cm!!.primaryClip!!.getItemAt(0)
            val description = cm!!.primaryClipDescription!!
            val label = description.label;
            var type = ContentType.Text;
            var content = item.coerceToText(context).toString()
            if (label.contains("image") && item.uri != null) {
                type = ContentType.Image;
                val contentResolver = context.contentResolver
                val currentTimeMillis = System.currentTimeMillis()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss-S", Locale.CHINA)
                val fileName = dateFormat.format(Date(currentTimeMillis))
                val cachePath = context.externalCacheDir?.absolutePath + "/" + fileName + ".png";
                Log.d(TAG, "cachePath $cachePath")
                try {
                    val inputStream = contentResolver.openInputStream(item.uri)
                    if (inputStream == null) {
                        Log.e(TAG, "Failed to open input stream for URI: ${item.uri}")
                        return;
                    }
                    val destFile = File(cachePath)
                    val outputStream: OutputStream = FileOutputStream(destFile)
                    val buffer = ByteArray(10240)
                    var length: Int
                    while (inputStream.read(buffer).also { length = it } > 0) {
                        outputStream.write(buffer, 0, length)
                    }
                    inputStream.close()
                    outputStream.close()
                    Log.d(TAG, "File copied successfully to: $cachePath")
                } catch (e: IOException) {
                    Log.e(TAG, "Error copying file: " + e.message)
                }
                content = cachePath;
            }
            val isSame = content == lastContent && type == lastType
            lastContent = content
            lastType = type
            for (observer in observers) {
                observer.clipboardChanged(type, content, isSame)
            }
        } catch (e: Exception) {
            e.printStackTrace()
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
            }
            return _instance
        }
    }


}