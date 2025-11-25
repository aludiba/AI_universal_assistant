package com.aiwriting.assistant

import android.app.Application
import com.aiwriting.assistant.data.local.AppDatabase
import com.aiwriting.assistant.data.repository.*
import com.aiwriting.assistant.utils.PreferenceManager

class AIWritingApplication : Application() {

    lateinit var database: AppDatabase
        private set

    lateinit var preferenceManager: PreferenceManager
        private set

    lateinit var dataRepository: DataRepository
        private set

    lateinit var wordPackRepository: WordPackRepository
        private set

    lateinit var vipRepository: VIPRepository
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this

        // 初始化数据库
        database = AppDatabase.getInstance(this)

        // 初始化偏好设置管理器
        preferenceManager = PreferenceManager(this)

        // 初始化仓库
        dataRepository = DataRepository(this, database)
        wordPackRepository = WordPackRepository(this)
        vipRepository = VIPRepository(this)
    }

    companion object {
        lateinit var instance: AIWritingApplication
            private set
    }
}

