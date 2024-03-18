package top.coclyun.clipshare.adapter

import android.content.ClipData
import android.content.ClipDescription
import android.util.Log
import android.view.DragEvent
import android.view.LayoutInflater
import android.view.View
import android.view.View.DragShadowBuilder
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import top.coclyun.clipshare.R


class HistoryFloatAdapter(
    private val dataList: List<String>,
    private val onDragStart: () -> Unit,
    private val onDragEnd: () -> Unit,
) : RecyclerView.Adapter<HistoryFloatViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HistoryFloatViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.history_float_item_layout, parent, false)
        return HistoryFloatViewHolder(view)
    }

    override fun onBindViewHolder(holder: HistoryFloatViewHolder, position: Int) {
        val item = dataList[position]
        holder.bind(item,onDragStart,onDragEnd)
    }

    override fun getItemCount(): Int {
        return dataList.size
    }
}

class HistoryFloatViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {

    private val textView = itemView.findViewById<TextView>(R.id.content)
    private val copy = itemView.findViewById<LinearLayout>(R.id.copy)

    fun bind(item: String, onDragStart: () -> Unit, onDragEnd: () -> Unit) {
        textView.text = item
//        copy.setOnClickListener{
//
//        }
        textView.setOnLongClickListener {
            //开始startDragAndDrop
            val item = ClipData.Item(item)
            val mimeTypes = arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN)
            val dragData = ClipData("ClipboardData", mimeTypes, item)
            val shadow = DragShadowBuilder(itemView)
            itemView.startDragAndDrop(dragData, shadow, null, View.DRAG_FLAG_GLOBAL)
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
    }
}