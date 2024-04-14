package top.coclyun.clipshare.adapter

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.view.DragEvent
import android.view.LayoutInflater
import android.view.View
import android.view.View.DragShadowBuilder
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat.getSystemService
import androidx.recyclerview.widget.RecyclerView
import top.coclyun.clipshare.MainActivity
import top.coclyun.clipshare.R
import kotlin.math.min


class HistoryFloatAdapter(
    dataList: List<String>,
    private val onDragStart: () -> Unit,
    private val onDragEnd: () -> Unit,
) : RecyclerView.Adapter<HistoryFloatViewHolder>() {
    private val dataList: MutableList<String> = dataList.toMutableList();
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HistoryFloatViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.history_float_item_layout, parent, false)
        return HistoryFloatViewHolder(view)
    }

    override fun onBindViewHolder(holder: HistoryFloatViewHolder, position: Int) {
        val item = dataList[position]
        holder.bind(item, onDragStart, onDragEnd)
    }

    override fun getItemCount(): Int {
        return dataList.size
    }

    fun addDataList(list: List<String>) {
        dataList.addAll(list)
        // 更新整个数据集
        notifyDataSetChanged()
    }
}

class HistoryFloatViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {

    private val textView = itemView.findViewById<TextView>(R.id.content)
    private val copy = itemView.findViewById<LinearLayout>(R.id.copy)

    fun bind(item: String, onDragStart: () -> Unit, onDragEnd: () -> Unit) {
        textView.text = item.substring(0, min(200, item.length))
        textView.setOnLongClickListener {
            //开始startDragAndDrop
            val mimeTypes = arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN)
            val dragData = ClipData("ClipboardData", mimeTypes, ClipData.Item(item))
            val shadow = DragShadowBuilder(textView)
            textView.startDragAndDrop(dragData, shadow, null, View.DRAG_FLAG_GLOBAL)
            false
        }
        textView.setOnDragListener { view, event ->
            when (event.action) {
                DragEvent.ACTION_DRAG_STARTED -> {
                    onDragStart()
                }

                DragEvent.ACTION_DRAG_ENDED -> {
                    onDragEnd()
                }
            }
            true
        }
        copy.setOnClickListener {
            MainActivity.innerCopy = true;
            // 获取剪贴板管理器
            val clipboardManager = getSystemService(
                itemView.context,
                ClipboardManager::class.java
            ) as ClipboardManager

            // 创建一个剪贴板数据
            val clipData = ClipData.newPlainText("ClipboardData", item)

            // 将数据放入剪贴板
            clipboardManager.setPrimaryClip(clipData)

        }
    }
}