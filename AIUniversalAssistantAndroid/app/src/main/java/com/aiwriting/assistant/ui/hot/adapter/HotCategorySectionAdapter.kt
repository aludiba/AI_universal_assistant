package com.aiwriting.assistant.ui.hot.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.aiwriting.assistant.data.model.HotCategory
import com.aiwriting.assistant.data.model.HotItem
import com.aiwriting.assistant.databinding.ItemHotCategorySectionBinding

class HotCategorySectionAdapter(
    private val categories: List<HotCategory>,
    private val isFavorite: (String) -> Boolean,
    private val onItemClick: (HotItem) -> Unit,
    private val onFavoriteClick: (HotItem, Boolean) -> Unit
) : RecyclerView.Adapter<HotCategorySectionAdapter.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemHotCategorySectionBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(categories[position])
    }

    override fun getItemCount() = categories.size

    inner class ViewHolder(private val binding: ItemHotCategorySectionBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(category: HotCategory) {
            binding.sectionTitle.text = category.title
            
            // 如果项目数量超过4个，显示"查看更多"
            binding.viewMore.visibility = if (category.items.size > 4) View.VISIBLE else View.GONE
            
            // 设置项目网格
            val itemAdapter = HotItemAdapter(
                items = category.items,
                isFavorite = isFavorite,
                onItemClick = onItemClick,
                onFavoriteClick = onFavoriteClick
            )
            
            binding.itemsRecyclerView.apply {
                layoutManager = GridLayoutManager(context, 2)
                adapter = itemAdapter
            }
        }
    }
}

