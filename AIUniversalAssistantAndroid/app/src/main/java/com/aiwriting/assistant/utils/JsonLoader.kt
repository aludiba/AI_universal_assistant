package com.aiwriting.assistant.utils

import android.content.Context
import com.aiwriting.assistant.data.model.HotCategory
import com.aiwriting.assistant.data.model.WritingCategory
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object JsonLoader {
    private val gson = Gson()

    suspend fun loadHotCategories(context: Context): List<HotCategory> = withContext(Dispatchers.IO) {
        try {
            val json = context.assets.open("hot_categories.json").bufferedReader().use { it.readText() }
            gson.fromJson(json, object : TypeToken<List<HotCategory>>() {}.type)
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }

    suspend fun loadWritingCategories(context: Context): List<WritingCategory> = withContext(Dispatchers.IO) {
        try {
            val json = context.assets.open("writing_categories.json").bufferedReader().use { it.readText() }
            gson.fromJson(json, object : TypeToken<List<WritingCategory>>() {}.type)
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }
}

