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

private data class IconInfo(val emoji: String, val backgroundRes: Int)

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
            
            // 设置图标和背景颜色
            val iconInfo = getIconInfo(item.icon, item.type)
            binding.iconView.text = iconInfo.emoji
            binding.iconBackground.setBackgroundResource(iconInfo.backgroundRes)

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

        private fun getIconInfo(icon: String, type: String): IconInfo {
            // 根据截图中的实际颜色分配图标背景
            // 根据 icon 和 type 返回对应的 emoji 和背景颜色
            return when {
                // 热门分类 - 根据截图颜色
                icon == "mic" || type == "speech" -> IconInfo("🎤", R.drawable.bg_icon_brown)
                icon == "heart" || type == "experience" -> IconInfo("❤️", R.drawable.bg_icon_red)
                icon == "edit" || type == "self_criticism" -> IconInfo("✏️", R.drawable.bg_icon_brown)
                icon == "graduationcap" || type == "internship" -> IconInfo("🎓", R.drawable.bg_icon_blue)
                icon == "square.and.pencil" || type == "xiaohongshu" -> IconInfo("📝", R.drawable.bg_icon_red)
                icon == "book" || type == "poetry" -> IconInfo("📚", R.drawable.bg_icon_purple)
                
                // 社媒分类
                icon == "newspaper" || type == "toutiao" -> IconInfo("📰", R.drawable.bg_icon_red)
                icon == "doc.richtext" || type == "wechat" -> IconInfo("📄", R.drawable.bg_icon_purple)
                icon == "questionmark" || type == "zhihu" -> IconInfo("❓", R.drawable.bg_icon_blue)
                icon == "person.2" || type == "moments" -> IconInfo("👥", R.drawable.bg_icon_purple)
                icon == "play.rectangle" || type == "video_script" -> IconInfo("🎬", R.drawable.bg_icon_blue)
                
                // 校园分类
                icon == "pencil" || type == "composition" -> IconInfo("✏️", R.drawable.bg_icon_brown)
                icon == "book.closed" || type == "book_review" -> IconInfo("📖", R.drawable.bg_icon_teal)
                icon == "doc.text" || type == "research" -> IconInfo("📄", R.drawable.bg_icon_blue)
                icon == "a.square" || type == "english" -> IconInfo("🔤", R.drawable.bg_icon_teal)
                icon == "lightbulb" || type == "gaokao" -> IconInfo("💡", R.drawable.bg_icon_purple)
                
                // 职场分类
                icon == "calendar" || type == "report" -> IconInfo("📅", R.drawable.bg_icon_teal)
                icon == "chart.bar" || type == "year_summary" -> IconInfo("📊", R.drawable.bg_icon_purple)
                icon == "square.stack" || type == "ppt" -> IconInfo("📚", R.drawable.bg_icon_teal)
                icon == "target" || type == "okr" -> IconInfo("🎯", R.drawable.bg_icon_orange)
                icon == "envelope" || type == "email" -> IconInfo("✉️", R.drawable.bg_icon_blue)
                
                // 营销分类
                icon == "quote.bubble" || type == "moments_ads" -> IconInfo("💬", R.drawable.bg_icon_purple)
                icon == "flame" || type == "hot_title" -> IconInfo("🔥", R.drawable.bg_icon_red)
                icon == "megaphone" || type == "live_commerce" -> IconInfo("📢", R.drawable.bg_icon_purple)
                icon == "tag" || type == "slogan" -> IconInfo("🏷️", R.drawable.bg_icon_teal)
                icon == "party.popper" || type == "campaign" -> IconInfo("🎉", R.drawable.bg_icon_blue)
                
                // 生活分类
                icon == "frying.pan" || type == "recipe" -> IconInfo("🍳", R.drawable.bg_icon_orange)
                icon == "airplane" || type == "travel" -> IconInfo("✈️", R.drawable.bg_icon_blue)
                icon == "heart.text" || type == "girlfriend_reply" -> IconInfo("💕", R.drawable.bg_icon_purple)
                icon == "hand.raised" || type == "apology" -> IconInfo("✋", R.drawable.bg_icon_purple)
                icon == "sparkles" || type == "horoscope" -> IconInfo("✨", R.drawable.bg_icon_purple)
                
                else -> IconInfo("📝", R.drawable.bg_icon_blue)
            }
        }
    }
}

