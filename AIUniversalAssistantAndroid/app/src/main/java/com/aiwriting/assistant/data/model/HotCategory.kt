package com.aiwriting.assistant.data.model

import kotlinx.serialization.Serializable

@Serializable
data class HotCategory(
    val id: String,
    val title: String,
    val isFavoriteCategory: Boolean = false,
    val items: List<HotItem> = emptyList()
)

