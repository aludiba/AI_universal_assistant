package com.aiwriting.assistant.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.*

@Entity(tableName = "writing_records")
data class WritingRecord(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val content: String,
    val prompt: String? = null,
    val theme: String? = null,
    val requirement: String? = null,
    val wordCount: Int? = null,
    val style: String? = null,
    val type: String,
    val createTime: Long = System.currentTimeMillis(),
    val updateTime: Long = System.currentTimeMillis()
)

