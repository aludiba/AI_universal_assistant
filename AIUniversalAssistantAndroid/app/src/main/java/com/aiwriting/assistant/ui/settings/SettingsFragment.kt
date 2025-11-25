package com.aiwriting.assistant.ui.settings

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import com.aiwriting.assistant.AIWritingApplication
import com.aiwriting.assistant.R
import com.aiwriting.assistant.databinding.FragmentSettingsBinding
import com.aiwriting.assistant.utils.CacheClearedEvent
import com.aiwriting.assistant.utils.formatFileSize
import com.aiwriting.assistant.utils.toast
import org.greenrobot.eventbus.EventBus

class SettingsFragment : Fragment() {
    private var _binding: FragmentSettingsBinding? = null
    private val binding get() = _binding!!
    
    private val dataRepository by lazy { AIWritingApplication.instance.dataRepository }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSettingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupViews()
        updateCacheSize()
    }

    private fun setupViews() {
        binding.clearCacheLayout.setOnClickListener {
            showClearCacheDialog()
        }
    }

    private fun updateCacheSize() {
        val cacheSize = dataRepository.calculateCacheSize()
        val formattedSize = cacheSize.formatFileSize()
        binding.cacheSizeText.text = formattedSize
    }

    private fun showClearCacheDialog() {
        val cacheSize = dataRepository.calculateCacheSize()
        
        if (cacheSize == 0L) {
            requireContext().toast(getString(R.string.cache_already_empty))
            return
        }

        val formattedSize = cacheSize.formatFileSize()
        val message = getString(R.string.clear_cache_message, formattedSize)

        AlertDialog.Builder(requireContext())
            .setTitle(R.string.clear_cache)
            .setMessage(message)
            .setPositiveButton(R.string.confirm) { _, _ ->
                clearCache()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun clearCache() {
        dataRepository.clearCache()
        updateCacheSize()
        requireContext().toast(getString(R.string.cache_cleared_success))
        EventBus.getDefault().post(CacheClearedEvent())
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}

