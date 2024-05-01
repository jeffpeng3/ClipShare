package top.coclyun.clipshare.service

import android.app.Service
import android.content.Intent
import android.content.res.Resources
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.View.INVISIBLE
import android.view.View.OnClickListener
import android.view.View.OnTouchListener
import android.view.View.VISIBLE
import android.view.ViewGroup
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import android.widget.LinearLayout
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.flutter.plugin.common.MethodChannel.Result
import top.coclyun.clipshare.MainActivity
import top.coclyun.clipshare.R
import top.coclyun.clipshare.adapter.HistoryFloatAdapter


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
    private val TAG = "HistoryFloatService"
    private var recyclerView: RecyclerView? = null
    private var minHistoryId = 0L
    private var loading = false;
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val layoutInflater = baseContext.getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        view = layoutInflater.inflate(R.layout.history_clipboard_float, null) as ViewGroup
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
        setPos1P3()
        mainParams.flags = LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCH_MODAL
        mainParams.gravity = Gravity.END or Gravity.CENTER
        val bar = view.findViewById<LinearLayout>(R.id.bar)
        recyclerView = view.findViewById(R.id.list)
        recyclerView?.layoutManager = LinearLayoutManager(view.context)
        bar.setOnTouchListener(this)
        view.setOnTouchListener(this)
        view.setOnClickListener(this)
        recyclerView?.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                super.onScrolled(recyclerView, dx, dy)
                val dist = getDistanceToBottom(recyclerView)
                Log.d(TAG, "onScrolled: $dist $dy")
                if (dist <= 5 && dy > 0) {
                    refreshData(true)
                }
            }
        })
        windowManager.addView(view, mainParams)
    }

    // 获取距离底部的距离
    fun getDistanceToBottom(recyclerView: RecyclerView): Int {
        val layoutManager = recyclerView.layoutManager
        val lastVisibleItemPosition =
            (layoutManager as LinearLayoutManager).findLastVisibleItemPosition()
        val totalItemCount = layoutManager.itemCount
        return totalItemCount - lastVisibleItemPosition
    }

    private fun closeFloatWindow() {
        windowManager.removeView(view);
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSelf()
        closeFloatWindow()
    }

    private fun setPosRight() {
        // 设置悬浮窗的位置
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels
        mainParams.x = 0
    }

    private fun setPos1P3() {
        // 设置悬浮窗的位置
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels
        // 垂直居中
        val yPosition: Int = -(screenHeight - view.height) / 3
        mainParams.x = 0
        mainParams.y = yPosition
    }

    override fun onTouch(v: View, event: MotionEvent): Boolean {
        Log.d("onTouch", event.action.toString())
        val bar = view.findViewById<LinearLayout>(R.id.bar)
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

                //未锁定位置
                if (!MainActivity.lockHistoryFloatLoc) {
                    //保持在窗口右边
                    mainParams.x = 0
                    mainParams.y = if (positionY != 0) positionY else mainParams.y + movedY
                    positionY = mainParams.y + movedY
                }
                if (movedX < -20) {
                    //向左滑动，显示列表
                    view.visibility = INVISIBLE
                    bar.visibility = View.GONE
                    showListView = true
                    //显示listview
                    recyclerView?.visibility = VISIBLE
                    setPosRight()
                    mainParams.width = LayoutParams.MATCH_PARENT
                    mainParams.height = LayoutParams.MATCH_PARENT
                    windowManager.updateViewLayout(view, mainParams)
                    view.post {
                        view.visibility = VISIBLE
                        refreshData()
                    }

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

    private fun refreshData(more: Boolean = false) {
        if (loading) return
        loading = true
        MainActivity.clipChannel.invokeMethod("getHistory",
            mapOf("fromId" to if (more) minHistoryId else 0L),
            object : Result {
                @Suppress("UNCHECKED_CAST")
                override fun success(result: Any?) {
                    val lst = result as List<Map<String, Any>>
                    if (lst.isNotEmpty()) {
                        minHistoryId = lst.last()["id"] as Long
                        val list = lst.map { it["content"].toString() }.toList()
                        if (more) {
                            (recyclerView?.adapter as HistoryFloatAdapter).addDataList(list);
                        } else {
                            // 创建并设置适配器
                            recyclerView?.adapter = HistoryFloatAdapter(list, {
                                view.visibility = INVISIBLE
                                mainParams.width = LayoutParams.WRAP_CONTENT
                                mainParams.x = 0
                                windowManager.updateViewLayout(view, mainParams)
                            }, {
                                mainParams.width = LayoutParams.MATCH_PARENT
//                                setPos1P3()
                                windowManager.updateViewLayout(view, mainParams)
                                view.post { view.visibility = VISIBLE }

                            })
                        }

                    }
                    loading = false
                }

                override fun error(
                    errorCode: String,
                    errorMessage: String?,
                    errorDetails: Any?
                ) {
                    TODO("Not yet implemented")
                }

                override fun notImplemented() {
                    TODO("Not yet implemented")
                }

            })
    }

    override fun onClick(v: View?) {
        if (!showListView) {
            return
        }
        hideRecycleView()
    }

    private fun hideRecycleView() {
        showListView = false
        val bar = view.findViewById<LinearLayout>(R.id.bar)
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        //隐藏listview
        recyclerView!!.visibility = if (showListView) View.VISIBLE else View.GONE
        windowManager.updateViewLayout(view, mainParams)
        val handler = Handler(Looper.getMainLooper())
        handler.postDelayed({
            bar.visibility = if (showListView) View.GONE else View.VISIBLE
            mainParams.x = lastPos[0]
//            mainParams.y = lastPos[1]
            windowManager.updateViewLayout(view, mainParams)
        }, 500)
    }

    private fun dp2px(dp: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            Resources.getSystem().displayMetrics
        )
    }
}