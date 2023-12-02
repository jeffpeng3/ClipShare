package top.coclyun.clipshare.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import top.coclyun.clipshare.ClipboardListener
import top.coclyun.clipshare.MainActivity

class BackgroundService : Service(){

    override fun onCreate() {
        super.onCreate()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null;
    }
}