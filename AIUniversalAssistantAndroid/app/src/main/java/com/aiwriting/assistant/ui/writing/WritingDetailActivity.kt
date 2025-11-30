package com.aiwriting.assistant.ui.writing

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.aiwriting.assistant.data.model.HotItem
import com.aiwriting.assistant.databinding.ActivityWritingDetailBinding

class WritingDetailActivity : AppCompatActivity() {
    private lateinit var binding: ActivityWritingDetailBinding
    private lateinit var item: HotItem

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityWritingDetailBinding.inflate(layoutInflater)
        setContentView(binding.root)

        item = intent.getParcelableExtra("item") ?: return

        setupToolbar()
        setupContent()
    }

    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = item.title
        binding.toolbar.setNavigationOnClickListener {
            finish()
        }
    }

    private fun setupContent() {
        binding.titleText.text = item.title
        binding.subtitleText.text = item.subtitle
        // TODO: 实现具体的写作功能
    }
}

