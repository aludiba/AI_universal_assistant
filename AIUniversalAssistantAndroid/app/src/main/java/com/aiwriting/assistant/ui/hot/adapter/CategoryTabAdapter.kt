package com.aiwriting.assistant.ui.hot.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.aiwriting.assistant.R
import com.aiwriting.assistant.data.model.HotCategory

class CategoryTabAdapter(
    private val categories: List<HotCategory>,
    private val onCategorySelected: (Int, HotCategory) -> Unit
) : RecyclerView.Adapter<CategoryTabAdapter.ViewHolder>() {

    private var selectedPosition = 0

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_category_tab, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val category = categories[position]
        val isSelected = position == selectedPosition
        
        holder.bind(category, isSelected) {
            val previousPosition = selectedPosition
            selectedPosition = position
            notifyItemChanged(previousPosition)
            notifyItemChanged(selectedPosition)
            onCategorySelected(position, category)
        }
    }

    override fun getItemCount() = categories.size

    fun setSelectedPosition(position: Int) {
        val previousPosition = selectedPosition
        selectedPosition = position
        notifyItemChanged(previousPosition)
        notifyItemChanged(selectedPosition)
    }

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tabText: TextView = itemView.findViewById(R.id.categoryTab)

        fun bind(category: HotCategory, isSelected: Boolean, onClick: () -> Unit) {
            val displayText = when {
                category.isFavoriteCategory -> "☆"
                else -> category.title
            }
            
            tabText.text = displayText
            tabText.setTextColor(
                itemView.context.getColor(
                    if (isSelected) R.color.colorPrimary else R.color.textSecondary
                )
            )
            tabText.setTypeface(null, if (isSelected) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL)
            
            // 显示/隐藏下划线指示器
            val indicator = itemView.findViewById<android.view.View>(R.id.indicator)
            indicator.visibility = if (isSelected) android.view.View.VISIBLE else android.view.View.GONE
            
            itemView.setOnClickListener { onClick() }
        }
    }
}

