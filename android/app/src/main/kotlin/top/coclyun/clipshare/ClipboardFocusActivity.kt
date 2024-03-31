package top.coclyun.clipshare

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity


class ClipboardFocusActivity : AppCompatActivity() {
    private val TAG = "ClipboardFloatActivity"

    companion object {
        @JvmStatic
        fun getIntent(context: Context): Intent {
            val startIntent =
                Intent(context.applicationContext, ClipboardFocusActivity::class.java)
            startIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK
            return startIntent
        }

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_clpboard_focus)
        // WindowManager.LayoutParams
        val wlp = window.attributes
        wlp.dimAmount = 0f
        wlp.flags = WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        window.attributes = wlp
//        Toast.makeText(this, "启动弹窗", Toast.LENGTH_SHORT).show()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            ClipboardListener.instance(this)!!.onClipboardChanged();
            finish()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        super.onBackPressed()
        moveTaskToBack(true)
    }
}