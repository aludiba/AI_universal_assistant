package com.aiwriting.assistant.data.repository

import android.content.Context
import com.aiwriting.assistant.data.local.AppDatabase
import com.aiwriting.assistant.data.model.*
import com.aiwriting.assistant.utils.JsonLoader
import com.aiwriting.assistant.utils.PreferenceManager
import kotlinx.coroutines.flow.Flow

class DataRepository(
    private val context: Context,
    private val database: AppDatabase
) {
    private val preferenceManager = PreferenceManager(context)
    private val writingRecordDao = database.writingRecordDao()
    private val documentDao = database.documentDao()

    // 热门分类
    suspend fun loadHotCategories(): List<HotCategory> {
        return JsonLoader.loadHotCategories(context)
    }

    // 写作分类
    suspend fun loadWritingCategories(): List<WritingCategory> {
        return JsonLoader.loadWritingCategories(context)
    }

    // 收藏
    fun getFavorites(): List<String> = preferenceManager.getFavorites()
    fun addFavorite(itemId: String) = preferenceManager.addFavorite(itemId)
    fun removeFavorite(itemId: String) = preferenceManager.removeFavorite(itemId)
    fun isFavorite(itemId: String): Boolean = preferenceManager.isFavorite(itemId)

    // 最近使用
    fun getRecentUsed(): List<String> = preferenceManager.getRecentUsed()
    fun addRecentUsed(itemId: String) = preferenceManager.addRecentUsed(itemId)
    fun clearRecentUsed() = preferenceManager.clearRecentUsed()

    // 搜索历史
    fun getSearchHistory(): List<String> = preferenceManager.getSearchHistory()
    fun addSearchHistory(keyword: String) = preferenceManager.addSearchHistory(keyword)
    fun clearSearchHistory() = preferenceManager.clearSearchHistory()

    // 写作记录
    fun getAllWritingRecords(): Flow<List<WritingRecord>> = writingRecordDao.getAllRecords()
    fun getWritingRecordsByType(type: String): Flow<List<WritingRecord>> = writingRecordDao.getRecordsByType(type)
    suspend fun getWritingRecordById(id: String): WritingRecord? = writingRecordDao.getRecordById(id)
    suspend fun saveWritingRecord(record: WritingRecord) = writingRecordDao.insertRecord(record)
    suspend fun updateWritingRecord(record: WritingRecord) = writingRecordDao.updateRecord(record)
    suspend fun deleteWritingRecord(record: WritingRecord) = writingRecordDao.deleteRecord(record)
    suspend fun deleteWritingRecordById(id: String) = writingRecordDao.deleteRecordById(id)

    // 文档
    fun getAllDocuments(): Flow<List<Document>> = documentDao.getAllDocuments()
    suspend fun getDocumentById(id: String): Document? = documentDao.getDocumentById(id)
    suspend fun saveDocument(document: Document) = documentDao.insertDocument(document)
    suspend fun updateDocument(document: Document) = documentDao.updateDocument(document)
    suspend fun deleteDocument(document: Document) = documentDao.deleteDocument(document)
    suspend fun deleteDocumentById(id: String) = documentDao.deleteDocumentById(id)

    // 缓存管理
    fun calculateCacheSize(): Long = preferenceManager.calculateCacheSize()
    
    fun formatCacheSize(bytes: Long): String {
        return when {
            bytes <= 0 -> "0 KB"
            bytes < 1024 -> "$bytes B"
            bytes < 1024 * 1024 -> String.format("%.1f KB", bytes / 1024.0)
            else -> String.format("%.1f MB", bytes / (1024.0 * 1024.0))
        }
    }

    fun clearCache() {
        preferenceManager.clearCache()
    }
}

