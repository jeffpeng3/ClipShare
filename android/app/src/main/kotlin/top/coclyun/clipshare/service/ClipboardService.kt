package top.coclyun.clipshare.service

import android.content.Context
import android.os.RemoteException
import android.util.Log
import androidx.annotation.Keep
import top.coclyun.clipshare.BuildConfig
import top.coclyun.clipshare.ClipboardFloatActivity
import top.coclyun.clipshare.IClipboardService
import top.coclyun.clipshare.INoArgsCallBack
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.HashSet;
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ClipboardService : IClipboardService.Stub() {
    @Throws(RemoteException::class)
    override fun destroy() {
        System.exit(0)
    }

    @Throws(RemoteException::class)
    override fun readLogs(callback: INoArgsCallBack) {
        Log.d("read_log", "before")
        Thread {
            readLog(callback)
        }.start()
    }

    private fun readLog(callback: INoArgsCallBack) {
        val timeStamp: String =
            SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
        val cmdStrArr = arrayOf(
            "logcat",
            "-T",
            timeStamp,
            "ClipboardService:E",
            "*:S"
        )
        Log.d("read_log", "start")
        val process = Runtime.getRuntime().exec(cmdStrArr)
        val bufferedReader = BufferedReader(InputStreamReader(process.inputStream))
        var line: String?
        
        while (bufferedReader.readLine().also { line = it } != null) {
            line?.let { Log.d("read_logs_it", "it:"+line) }
            line?.let { Log.d("read_logs", BuildConfig.APPLICATION_ID+" BuildConfig.APPLICATION_ID") }
            if (line!!.contains(BuildConfig.APPLICATION_ID)) {

                line?.let { Log.d("read_logs", "callback.call") }
                callback.call();
                line?.let { Log.d("read_logs", "callback.call after") }
//                context.startActivity(ClipboardFloatActivity.getIntent(context))
            }
        }
        Log.d("read_logs", "finished")
    }
}