package com.aiwriting.assistant.data.model

import kotlinx.serialization.Serializable

@Serializable
data class WritingCategory(
    val title: String,
    val items: List<WritingTemplate>
)

@Serializable
data class WritingTemplate(
    val title: String,
    val content: String
)

