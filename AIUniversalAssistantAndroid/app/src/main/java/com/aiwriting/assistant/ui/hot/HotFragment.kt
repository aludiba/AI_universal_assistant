package com.aiwriting.assistant.ui.hot

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.aiwriting.assistant.AIWritingApplication
import com.aiwriting.assistant.databinding.FragmentHotBinding
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
        loadData()
    }

    private fun loadData() {
        lifecycleScope.launch {
            try {
                val categories = dataRepository.loadHotCategories()
                // TODO: 设置RecyclerView适配器显示分类数据
                requireContext().toast("加载了 ${categories.size} 个分类")
            } catch (e: Exception) {
                requireContext().toast("加载失败: ${e.message}")
            }
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

