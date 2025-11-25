package com.aiwriting.assistant.data.model

import kotlinx.serialization.Serializable

@Serializable
data class HotCategory(
    val id: String,
    val title: String,
    val isFavoriteCategory: Boolean = false,
    val items: List<HotItem> = emptyList()
)

@Serializable
data class HotItem(
    val title: String,
    val subtitle: String,
    val icon: String,
    val type: String,
    val categoryId: String,
    val categoryTitle: String
) {
    fun getUniqueId(): String = "${categoryId}_${type}_$title"
}

