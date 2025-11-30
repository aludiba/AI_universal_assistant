package com.aiwriting.assistant.ui.hot

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.aiwriting.assistant.AIWritingApplication
import com.aiwriting.assistant.databinding.FragmentHotBinding
import com.aiwriting.assistant.data.model.HotCategory
import com.aiwriting.assistant.data.model.HotItem
import com.aiwriting.assistant.ui.hot.adapter.CategoryTabAdapter
import com.aiwriting.assistant.ui.hot.adapter.HotCategorySectionAdapter
import com.aiwriting.assistant.ui.writing.WritingDetailActivity
import com.aiwriting.assistant.utils.toast
import kotlinx.coroutines.launch
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode
import com.aiwriting.assistant.utils.CacheClearedEvent

class HotFragment : Fragment() {
    private var _binding: FragmentHotBinding? = null
    private val binding get() = _binding!!
    
    private val dataRepository by lazy { AIWritingApplication.instance.dataRepository }
    private var allCategories: List<HotCategory> = emptyList()
    private var currentSelectedCategory: HotCategory? = null
    private var categoryTabAdapter: CategoryTabAdapter? = null
    private var categorySectionAdapter: HotCategorySectionAdapter? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHotBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        EventBus.getDefault().register(this)
        setupSearchBar()
        setupRecyclerViews()
        loadData()
    }

    private fun setupSearchBar() {
        binding.searchEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                filterCategories(s?.toString() ?: "")
            }
        })
    }

    private fun setupRecyclerViews() {
        // 分类标签横向滚动
        binding.categoryRecyclerView.layoutManager = LinearLayoutManager(
            requireContext(),
            LinearLayoutManager.HORIZONTAL,
            false
        )

        // 内容区域
        binding.contentRecyclerView.layoutManager = LinearLayoutManager(requireContext())
    }

    private fun loadData() {
        lifecycleScope.launch {
            try {
                allCategories = dataRepository.loadHotCategories()
                setupCategoryTabs()
                showCategoryContent(0)
            } catch (e: Exception) {
                requireContext().toast("加载失败: ${e.message}")
            }
        }
    }

    private fun setupCategoryTabs() {
        categoryTabAdapter = CategoryTabAdapter(allCategories) { position, category ->
            showCategoryContent(position)
        }
        binding.categoryRecyclerView.adapter = categoryTabAdapter
    }

    private fun showCategoryContent(position: Int) {
        if (position < 0 || position >= allCategories.size) return
        
        val category = allCategories[position]
        currentSelectedCategory = category

        // 如果是收藏分类，显示收藏页面内容
        if (category.isFavoriteCategory) {
            showFavoritesContent()
        } else {
            // 显示该分类的内容
            val filteredCategories = listOf(category)
            categorySectionAdapter = HotCategorySectionAdapter(
                categories = filteredCategories,
                isFavorite = { itemId -> dataRepository.isFavorite(itemId) },
                onItemClick = { item -> onItemClick(item) },
                onFavoriteClick = { item, isFavorite -> onFavoriteClick(item, isFavorite) }
            )
            binding.contentRecyclerView.adapter = categorySectionAdapter
        }
    }

    private fun showFavoritesContent() {
        // 获取收藏和最近使用的项目
        val favoriteIds = dataRepository.getFavorites()
        val recentUsedIds = dataRepository.getRecentUsed()

        // 从所有分类中查找收藏的项目
        val favoriteItems = mutableListOf<HotItem>()
        val recentUsedItems = mutableListOf<HotItem>()

        allCategories.forEach { category ->
            category.items.forEach { item ->
                val itemId = item.getUniqueId()
                if (favoriteIds.contains(itemId)) {
                    favoriteItems.add(item)
                }
                if (recentUsedIds.contains(itemId)) {
                    recentUsedItems.add(item)
                }
            }
        }

        // 创建收藏分类数据
        val favoritesCategory = HotCategory(
            id = "favorites",
            title = "我的关注",
            isFavoriteCategory = false,
            items = favoriteItems
        )

        val recentCategory = HotCategory(
            id = "recent",
            title = "最近使用",
            isFavoriteCategory = false,
            items = recentUsedItems
        )

        val favoritesCategories = mutableListOf<HotCategory>()
        if (favoriteItems.isNotEmpty()) {
            favoritesCategories.add(favoritesCategory)
        }
        if (recentUsedItems.isNotEmpty()) {
            favoritesCategories.add(recentCategory)
        }

        categorySectionAdapter = HotCategorySectionAdapter(
            categories = favoritesCategories,
            isFavorite = { itemId -> dataRepository.isFavorite(itemId) },
            onItemClick = { item -> onItemClick(item) },
            onFavoriteClick = { item, isFavorite -> onFavoriteClick(item, isFavorite) }
        )
        binding.contentRecyclerView.adapter = categorySectionAdapter
    }

    private fun filterCategories(keyword: String) {
        if (keyword.isBlank()) {
            // 恢复显示当前选中的分类
            val position = allCategories.indexOf(currentSelectedCategory)
            if (position >= 0) {
                showCategoryContent(position)
            }
            return
        }

        // 搜索所有分类中的项目
        val filteredItems = mutableListOf<HotItem>()
        allCategories.forEach { category ->
            if (!category.isFavoriteCategory) {
                category.items.forEach { item ->
                    if (item.title.contains(keyword, ignoreCase = true) ||
                        item.subtitle.contains(keyword, ignoreCase = true)
                    ) {
                        filteredItems.add(item)
                    }
                }
            }
        }

        // 创建搜索结果分类
        val searchCategory = HotCategory(
            id = "search",
            title = "搜索结果",
            isFavoriteCategory = false,
            items = filteredItems
        )

        categorySectionAdapter = HotCategorySectionAdapter(
            categories = listOf(searchCategory),
            isFavorite = { itemId -> dataRepository.isFavorite(itemId) },
            onItemClick = { item -> onItemClick(item) },
            onFavoriteClick = { item, isFavorite -> onFavoriteClick(item, isFavorite) }
        )
        binding.contentRecyclerView.adapter = categorySectionAdapter
    }

    private fun onItemClick(item: HotItem) {
        // 记录最近使用
        val itemId = item.getUniqueId()
        dataRepository.addRecentUsed(itemId)

        // 跳转到写作详情页面
        val intent = Intent(requireContext(), WritingDetailActivity::class.java).apply {
            putExtra("item", item)
        }
        startActivity(intent)
    }

    private fun onFavoriteClick(item: HotItem, isFavorite: Boolean) {
        val itemId = item.getUniqueId()
        if (isFavorite) {
            dataRepository.addFavorite(itemId)
            requireContext().toast("已收藏")
        } else {
            dataRepository.removeFavorite(itemId)
            requireContext().toast("已取消收藏")
        }

        // 刷新当前显示
        val position = allCategories.indexOf(currentSelectedCategory)
        if (position >= 0) {
            showCategoryContent(position)
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    fun onCacheCleared(event: CacheClearedEvent) {
        loadData()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        EventBus.getDefault().unregister(this)
        _binding = null
    }
}
