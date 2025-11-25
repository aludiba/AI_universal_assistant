package com.aiwriting.assistant.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.aiwriting.assistant.data.model.Document
import com.aiwriting.assistant.data.model.WritingRecord

@Database(
    entities = [WritingRecord::class, Document::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun writingRecordDao(): WritingRecordDao
    abstract fun documentDao(): DocumentDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "ai_writing_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}

