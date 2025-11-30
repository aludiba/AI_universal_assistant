package com.aiwriting.assistant.ui.hot.adapter

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.aiwriting.assistant.R
import com.aiwriting.assistant.data.model.HotItem
import com.aiwriting.assistant.databinding.ItemHotItemBinding

class HotItemAdapter(
    private val items: List<HotItem>,
    private val isFavorite: (String) -> Boolean,
    private val onItemClick: (HotItem) -> Unit,
    private val onFavoriteClick: (HotItem, Boolean) -> Unit
) : RecyclerView.Adapter<HotItemAdapter.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemHotItemBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    inner class ViewHolder(private val binding: ItemHotItemBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(item: HotItem) {
            val itemId = item.getUniqueId()
            val favorited = isFavorite(itemId)

            binding.titleText.text = item.title
            binding.subtitleText.text = item.subtitle
            
            // 设置图标（这里可以根据 icon 字段设置不同的图标）
            binding.iconView.text = getIconEmoji(item.icon)

            // 设置收藏按钮状态
            binding.favoriteButton.setImageResource(
                if (favorited) android.R.drawable.star_big_on else android.R.drawable.star_big_off
            )
            binding.favoriteButton.imageTintList = ContextCompat.getColorStateList(
                binding.root.context,
                if (favorited) R.color.vipGold else R.color.textSecondary
            )

            // 点击卡片
            binding.root.setOnClickListener {
                onItemClick(item)
            }

            // 点击收藏按钮
            binding.favoriteButton.setOnClickListener {
                onFavoriteClick(item, !favorited)
            }
        }

        private fun getIconEmoji(icon: String): String {
            // 根据 icon 字段返回对应的 emoji 或图标
            return when (icon) {
                "mic" -> "🎤"
                "heart" -> "❤️"
                "edit" -> "✏️"
                "graduationcap" -> "🎓"
                "square.and.pencil" -> "📝"
                "book" -> "📚"
                "newspaper" -> "📰"
                "doc.richtext" -> "📄"
                "questionmark" -> "❓"
                "person.2" -> "👥"
                "play.rectangle" -> "🎬"
                "pencil" -> "✏️"
                "book.closed" -> "📖"
                "doc.text" -> "📄"
                "a.square" -> "🔤"
                "lightbulb" -> "💡"
                "calendar" -> "📅"
                "chart.bar" -> "📊"
                "square.stack" -> "📚"
                "target" -> "🎯"
                "envelope" -> "✉️"
                "quote.bubble" -> "💬"
                "flame" -> "🔥"
                "megaphone" -> "📢"
                "tag" -> "🏷️"
                "party.popper" -> "🎉"
                "frying.pan" -> "🍳"
                "airplane" -> "✈️"
                "heart.text" -> "💕"
                "hand.raised" -> "✋"
                "sparkles" -> "✨"
                else -> "📝"
            }
        }
    }
}

