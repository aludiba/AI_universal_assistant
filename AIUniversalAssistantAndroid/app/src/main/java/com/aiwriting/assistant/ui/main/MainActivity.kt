package com.aiwriting.assistant.ui.main

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.aiwriting.assistant.R
import com.aiwriting.assistant.databinding.ActivityMainBinding
import com.aiwriting.assistant.ui.docs.DocsFragment
import com.aiwriting.assistant.ui.hot.HotFragment
import com.aiwriting.assistant.ui.settings.SettingsFragment
import com.aiwriting.assistant.ui.writer.WriterFragment

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private var currentFragment: Fragment? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupBottomNavigation()
        
        // 默认显示热门页面
        if (savedInstanceState == null) {
            switchFragment(HotFragment())
        }
    }

    private fun setupBottomNavigation() {
        binding.bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.navigation_hot -> {
                    switchFragment(HotFragment())
                    true
                }
                R.id.navigation_writer -> {
                    switchFragment(WriterFragment())
                    true
                }
                R.id.navigation_docs -> {
                    switchFragment(DocsFragment())
                    true
                }
                R.id.navigation_settings -> {
                    switchFragment(SettingsFragment())
                    true
                }
                else -> false
            }
        }
    }

    private fun switchFragment(fragment: Fragment) {
        if (currentFragment?.javaClass == fragment.javaClass) return
        
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .commit()
        
        currentFragment = fragment
    }
}

