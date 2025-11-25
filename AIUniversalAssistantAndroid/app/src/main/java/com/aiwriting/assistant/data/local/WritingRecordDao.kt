package com.aiwriting.assistant.data.local

import androidx.room.*
import com.aiwriting.assistant.data.model.WritingRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface WritingRecordDao {
    @Query("SELECT * FROM writing_records ORDER BY updateTime DESC")
    fun getAllRecords(): Flow<List<WritingRecord>>

    @Query("SELECT * FROM writing_records WHERE type = :type ORDER BY updateTime DESC")
    fun getRecordsByType(type: String): Flow<List<WritingRecord>>

    @Query("SELECT * FROM writing_records WHERE id = :id")
    suspend fun getRecordById(id: String): WritingRecord?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecord(record: WritingRecord)

    @Update
    suspend fun updateRecord(record: WritingRecord)

    @Delete
    suspend fun deleteRecord(record: WritingRecord)

    @Query("DELETE FROM writing_records WHERE id = :id")
    suspend fun deleteRecordById(id: String)

    @Query("DELETE FROM writing_records")
    suspend fun deleteAllRecords()
}

