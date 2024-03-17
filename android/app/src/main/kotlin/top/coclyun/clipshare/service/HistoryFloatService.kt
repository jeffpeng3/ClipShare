package top.coclyun.clipshare.service

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.View.OnClickListener
import android.view.View.OnTouchListener
import android.view.ViewGroup
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import android.widget.Button
import android.widget.LinearLayout
import top.coclyun.clipshare.R
import kotlin.math.max


class HistoryFloatService : Service(), OnTouchListener, OnClickListener {
    private lateinit var windowManager: WindowManager
    private lateinit var mainParams: LayoutParams
    private lateinit var view: ViewGroup
    private var x = 0
    private var y = 0
    private var downTime: Long = 0
    private var positionX = 0
    private var positionY = 0
    private var showListView = false
    private var lastPos = arrayOf(0, 0)
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val layoutInflater = baseContext.getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        view = layoutInflater.inflate(R.layout.activity_clipboard_float, null) as ViewGroup
        mainParams = LayoutParams()
    }


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        showFloatWindow()
        return START_STICKY
    }

    private fun showFloatWindow() {
        if (!Settings.canDrawOverlays(this)) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mainParams.type = LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            mainParams.type = LayoutParams.TYPE_PHONE;
        }
        mainParams.format = PixelFormat.RGBA_8888;
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        // 设置悬浮窗的位置
        setPosCenter()
        mainParams.flags = LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCH_MODAL
        mainParams.gravity = Gravity.LEFT or Gravity.TOP
        val bar = view.findViewById<LinearLayout>(R.id.bar)
        val listView = view.findViewById<LinearLayout>(R.id.list)
        val btn = view.findViewById<Button>(R.id.btn)
        btn.setOnClickListener {
            Log.d("showFloatWindow", "showFloatWindow: btn123123")
        }
        listView.setOnClickListener { true }
        bar.setOnTouchListener(this)
        view.setOnTouchListener(this)
        view.setOnClickListener(this)
        windowManager.addView(view, mainParams)
    }

    private fun closeFloatWindow() {
        windowManager.removeView(view);
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSelf()
        closeFloatWindow()
    }

    private fun setPosCenter() {
        // 设置悬浮窗的位置
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels
        // 屏幕右侧
        val xPosition: Int = screenWidth - view.width
        // 垂直居中
        val yPosition: Int = (screenHeight - view.height) / 2
        mainParams.x = xPosition
        mainParams.y = yPosition
    }

    override fun onTouch(v: View, event: MotionEvent): Boolean {
        Log.d("onTouch", event.action.toString())
        val bar = view.findViewById<LinearLayout>(R.id.bar)
        val listView = view.findViewById<LinearLayout>(R.id.list)
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                downTime = System.currentTimeMillis()
                x = event.rawX.toInt()
                y = event.rawY.toInt()
                v.performClick()
                return true
            }

            MotionEvent.ACTION_UP -> {
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                val nowX = event.rawX.toInt()
                val nowY = event.rawY.toInt()
                val movedX = nowX - x
                val movedY = nowY - y
                x = nowX
                y = nowY
                // 设置悬浮窗的位置
                val metrics = resources.displayMetrics
                val screenWidth = metrics.widthPixels
                val tempX = if (positionX != 0) positionX else mainParams.x + movedX

                //保持在窗口右边
                positionX = mainParams.x + movedX
                mainParams.x = max(screenWidth, tempX)
                mainParams.y = if (positionY != 0) positionY else mainParams.y + movedY
                positionY = mainParams.y + movedY
                if (movedX < -20) {
                    //向左滑动，显示列表
                    bar.visibility = View.GONE
                    showListView = true
                    val handler = Handler(Looper.getMainLooper())
                    handler.postDelayed({
                        //显示listview
                        listView.visibility = View.VISIBLE
                        setPosCenter()
                        mainParams.width = LayoutParams.MATCH_PARENT
                        mainParams.height = LayoutParams.MATCH_PARENT
                        windowManager.updateViewLayout(view, mainParams)
                    }, 0)
                } else if (!showListView) {
                    lastPos = arrayOf(positionX, positionY)
                }
                windowManager.updateViewLayout(view, mainParams)
                return true
            }

            else -> {}
        }
        return false
    }

    override fun onClick(v: View?) {
        if (!showListView) {
            return
        }
        showListView = false
        val bar = view.findViewById<LinearLayout>(R.id.bar)
        val listView = view.findViewById<LinearLayout>(R.id.list)
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        //隐藏listview
        listView.visibility = if (showListView) View.VISIBLE else View.GONE
        windowManager.updateViewLayout(view, mainParams)
        val handler = Handler(Looper.getMainLooper())
        handler.postDelayed({
            bar.visibility = if (showListView) View.GONE else View.VISIBLE
            mainParams.x = lastPos[0]
            mainParams.y = lastPos[1]
            windowManager.updateViewLayout(view, mainParams)
        }, 500)
    }
}