package com.aiwriting.assistant.utils

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class PreferenceManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson = Gson()

    companion object {
        private const val PREFS_NAME = "ai_writing_prefs"
        private const val KEY_FAVORITES = "favorites"
        private const val KEY_RECENT_USED = "recent_used"
        private const val KEY_SEARCH_HISTORY = "search_history"
        private const val KEY_VIP_GIFT = "vip_gift"
        private const val KEY_WORD_PACKS = "word_packs"
        private const val KEY_CONSUMED_WORDS = "consumed_words"
        private const val KEY_LAST_REFRESH_DATE = "last_refresh_date"
        private const val KEY_SUBSCRIPTION = "subscription"
    }

    // 收藏列表
    fun getFavorites(): List<String> {
        val json = prefs.getString(KEY_FAVORITES, null) ?: return emptyList()
        return gson.fromJson(json, object : TypeToken<List<String>>() {}.type)
    }

    fun saveFavorites(favorites: List<String>) {
        prefs.edit().putString(KEY_FAVORITES, gson.toJson(favorites)).apply()
    }

    fun addFavorite(itemId: String) {
        val favorites = getFavorites().toMutableList()
        if (!favorites.contains(itemId)) {
            favorites.add(itemId)
            saveFavorites(favorites)
        }
    }

    fun removeFavorite(itemId: String) {
        val favorites = getFavorites().toMutableList()
        favorites.remove(itemId)
        saveFavorites(favorites)
    }

    fun isFavorite(itemId: String): Boolean {
        return getFavorites().contains(itemId)
    }

    // 最近使用
    fun getRecentUsed(): List<String> {
        val json = prefs.getString(KEY_RECENT_USED, null) ?: return emptyList()
        return gson.fromJson(json, object : TypeToken<List<String>>() {}.type)
    }

    fun saveRecentUsed(recentUsed: List<String>) {
        prefs.edit().putString(KEY_RECENT_USED, gson.toJson(recentUsed)).apply()
    }

    fun addRecentUsed(itemId: String) {
        val recentUsed = getRecentUsed().toMutableList()
        recentUsed.remove(itemId)
        recentUsed.add(0, itemId)
        if (recentUsed.size > 20) {
            recentUsed.removeAt(recentUsed.size - 1)
        }
        saveRecentUsed(recentUsed)
    }

    fun clearRecentUsed() {
        prefs.edit().remove(KEY_RECENT_USED).apply()
    }

    // 搜索历史
    fun getSearchHistory(): List<String> {
        val json = prefs.getString(KEY_SEARCH_HISTORY, null) ?: return emptyList()
        return gson.fromJson(json, object : TypeToken<List<String>>() {}.type)
    }

    fun saveSearchHistory(history: List<String>) {
        prefs.edit().putString(KEY_SEARCH_HISTORY, gson.toJson(history)).apply()
    }

    fun addSearchHistory(keyword: String) {
        if (keyword.isBlank()) return
        val history = getSearchHistory().toMutableList()
        history.remove(keyword)
        history.add(0, keyword)
        if (history.size > 20) {
            history.removeAt(history.size - 1)
        }
        saveSearchHistory(history)
    }

    fun clearSearchHistory() {
        prefs.edit().remove(KEY_SEARCH_HISTORY).apply()
    }

    // 字数包相关
    fun saveWordPacks(json: String) {
        prefs.edit().putString(KEY_WORD_PACKS, json).apply()
    }

    fun getWordPacks(): String? {
        return prefs.getString(KEY_WORD_PACKS, null)
    }

    fun saveVIPGift(json: String) {
        prefs.edit().putString(KEY_VIP_GIFT, json).apply()
    }

    fun getVIPGift(): String? {
        return prefs.getString(KEY_VIP_GIFT, null)
    }

    fun saveConsumedWords(words: Int) {
        prefs.edit().putInt(KEY_CONSUMED_WORDS, words).apply()
    }

    fun getConsumedWords(): Int {
        return prefs.getInt(KEY_CONSUMED_WORDS, 0)
    }

    fun saveLastRefreshDate(date: String) {
        prefs.edit().putString(KEY_LAST_REFRESH_DATE, date).apply()
    }

    fun getLastRefreshDate(): String? {
        return prefs.getString(KEY_LAST_REFRESH_DATE, null)
    }

    // 订阅信息
    fun saveSubscription(json: String) {
        prefs.edit().putString(KEY_SUBSCRIPTION, json).apply()
    }

    fun getSubscription(): String? {
        return prefs.getString(KEY_SUBSCRIPTION, null)
    }

    // 计算缓存大小
    fun calculateCacheSize(): Long {
        var size = 0L
        prefs.getString(KEY_RECENT_USED, null)?.let { size += it.toByteArray().size }
        prefs.getString(KEY_SEARCH_HISTORY, null)?.let { size += it.toByteArray().size }
        return size
    }

    // 清理缓存
    fun clearCache() {
        prefs.edit()
            .remove(KEY_RECENT_USED)
            .remove(KEY_SEARCH_HISTORY)
            .apply()
    }
}

