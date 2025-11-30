package com.aiwriting.assistant.data.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import kotlinx.serialization.Serializable

@Serializable
@Parcelize
data class HotItem(
    val title: String,
    val subtitle: String,
    val icon: String,
    val type: String,
    val categoryId: String,
    val categoryTitle: String
) : Parcelable {
    fun getUniqueId(): String = "${categoryId}_${type}_$title"
}

