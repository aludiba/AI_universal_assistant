package com.aiwriting.assistant.data.local;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.aiwriting.assistant.data.model.WritingRecord;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Integer;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class WritingRecordDao_Impl implements WritingRecordDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<WritingRecord> __insertionAdapterOfWritingRecord;

  private final EntityDeletionOrUpdateAdapter<WritingRecord> __deletionAdapterOfWritingRecord;

  private final EntityDeletionOrUpdateAdapter<WritingRecord> __updateAdapterOfWritingRecord;

  private final SharedSQLiteStatement __preparedStmtOfDeleteRecordById;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAllRecords;

  public WritingRecordDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfWritingRecord = new EntityInsertionAdapter<WritingRecord>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `writing_records` (`id`,`title`,`content`,`prompt`,`theme`,`requirement`,`wordCount`,`style`,`type`,`createTime`,`updateTime`) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final WritingRecord entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getContent());
        if (entity.getPrompt() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getPrompt());
        }
        if (entity.getTheme() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getTheme());
        }
        if (entity.getRequirement() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getRequirement());
        }
        if (entity.getWordCount() == null) {
          statement.bindNull(7);
        } else {
          statement.bindLong(7, entity.getWordCount());
        }
        if (entity.getStyle() == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, entity.getStyle());
        }
        statement.bindString(9, entity.getType());
        statement.bindLong(10, entity.getCreateTime());
        statement.bindLong(11, entity.getUpdateTime());
      }
    };
    this.__deletionAdapterOfWritingRecord = new EntityDeletionOrUpdateAdapter<WritingRecord>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "DELETE FROM `writing_records` WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final WritingRecord entity) {
        statement.bindString(1, entity.getId());
      }
    };
    this.__updateAdapterOfWritingRecord = new EntityDeletionOrUpdateAdapter<WritingRecord>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "UPDATE OR ABORT `writing_records` SET `id` = ?,`title` = ?,`content` = ?,`prompt` = ?,`theme` = ?,`requirement` = ?,`wordCount` = ?,`style` = ?,`type` = ?,`createTime` = ?,`updateTime` = ? WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final WritingRecord entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getContent());
        if (entity.getPrompt() == null) {
          statement.bindNull(4);
        } else {
          statement.bindString(4, entity.getPrompt());
        }
        if (entity.getTheme() == null) {
          statement.bindNull(5);
        } else {
          statement.bindString(5, entity.getTheme());
        }
        if (entity.getRequirement() == null) {
          statement.bindNull(6);
        } else {
          statement.bindString(6, entity.getRequirement());
        }
        if (entity.getWordCount() == null) {
          statement.bindNull(7);
        } else {
          statement.bindLong(7, entity.getWordCount());
        }
        if (entity.getStyle() == null) {
          statement.bindNull(8);
        } else {
          statement.bindString(8, entity.getStyle());
        }
        statement.bindString(9, entity.getType());
        statement.bindLong(10, entity.getCreateTime());
        statement.bindLong(11, entity.getUpdateTime());
        statement.bindString(12, entity.getId());
      }
    };
    this.__preparedStmtOfDeleteRecordById = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM writing_records WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAllRecords = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM writing_records";
        return _query;
      }
    };
  }

  @Override
  public Object insertRecord(final WritingRecord record,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfWritingRecord.insert(record);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteRecord(final WritingRecord record,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __deletionAdapterOfWritingRecord.handle(record);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object updateRecord(final WritingRecord record,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __updateAdapterOfWritingRecord.handle(record);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteRecordById(final String id, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteRecordById.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, id);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteRecordById.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAllRecords(final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAllRecords.acquire();
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteAllRecords.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<WritingRecord>> getAllRecords() {
    final String _sql = "SELECT * FROM writing_records ORDER BY updateTime DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"writing_records"}, new Callable<List<WritingRecord>>() {
      @Override
      @NonNull
      public List<WritingRecord> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfPrompt = CursorUtil.getColumnIndexOrThrow(_cursor, "prompt");
          final int _cursorIndexOfTheme = CursorUtil.getColumnIndexOrThrow(_cursor, "theme");
          final int _cursorIndexOfRequirement = CursorUtil.getColumnIndexOrThrow(_cursor, "requirement");
          final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
          final int _cursorIndexOfStyle = CursorUtil.getColumnIndexOrThrow(_cursor, "style");
          final int _cursorIndexOfType = CursorUtil.getColumnIndexOrThrow(_cursor, "type");
          final int _cursorIndexOfCreateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "createTime");
          final int _cursorIndexOfUpdateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "updateTime");
          final List<WritingRecord> _result = new ArrayList<WritingRecord>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final WritingRecord _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpContent;
            _tmpContent = _cursor.getString(_cursorIndexOfContent);
            final String _tmpPrompt;
            if (_cursor.isNull(_cursorIndexOfPrompt)) {
              _tmpPrompt = null;
            } else {
              _tmpPrompt = _cursor.getString(_cursorIndexOfPrompt);
            }
            final String _tmpTheme;
            if (_cursor.isNull(_cursorIndexOfTheme)) {
              _tmpTheme = null;
            } else {
              _tmpTheme = _cursor.getString(_cursorIndexOfTheme);
            }
            final String _tmpRequirement;
            if (_cursor.isNull(_cursorIndexOfRequirement)) {
              _tmpRequirement = null;
            } else {
              _tmpRequirement = _cursor.getString(_cursorIndexOfRequirement);
            }
            final Integer _tmpWordCount;
            if (_cursor.isNull(_cursorIndexOfWordCount)) {
              _tmpWordCount = null;
            } else {
              _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
            }
            final String _tmpStyle;
            if (_cursor.isNull(_cursorIndexOfStyle)) {
              _tmpStyle = null;
            } else {
              _tmpStyle = _cursor.getString(_cursorIndexOfStyle);
            }
            final String _tmpType;
            _tmpType = _cursor.getString(_cursorIndexOfType);
            final long _tmpCreateTime;
            _tmpCreateTime = _cursor.getLong(_cursorIndexOfCreateTime);
            final long _tmpUpdateTime;
            _tmpUpdateTime = _cursor.getLong(_cursorIndexOfUpdateTime);
            _item = new WritingRecord(_tmpId,_tmpTitle,_tmpContent,_tmpPrompt,_tmpTheme,_tmpRequirement,_tmpWordCount,_tmpStyle,_tmpType,_tmpCreateTime,_tmpUpdateTime);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Flow<List<WritingRecord>> getRecordsByType(final String type) {
    final String _sql = "SELECT * FROM writing_records WHERE type = ? ORDER BY updateTime DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, type);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"writing_records"}, new Callable<List<WritingRecord>>() {
      @Override
      @NonNull
      public List<WritingRecord> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfPrompt = CursorUtil.getColumnIndexOrThrow(_cursor, "prompt");
          final int _cursorIndexOfTheme = CursorUtil.getColumnIndexOrThrow(_cursor, "theme");
          final int _cursorIndexOfRequirement = CursorUtil.getColumnIndexOrThrow(_cursor, "requirement");
          final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
          final int _cursorIndexOfStyle = CursorUtil.getColumnIndexOrThrow(_cursor, "style");
          final int _cursorIndexOfType = CursorUtil.getColumnIndexOrThrow(_cursor, "type");
          final int _cursorIndexOfCreateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "createTime");
          final int _cursorIndexOfUpdateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "updateTime");
          final List<WritingRecord> _result = new ArrayList<WritingRecord>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final WritingRecord _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpContent;
            _tmpContent = _cursor.getString(_cursorIndexOfContent);
            final String _tmpPrompt;
            if (_cursor.isNull(_cursorIndexOfPrompt)) {
              _tmpPrompt = null;
            } else {
              _tmpPrompt = _cursor.getString(_cursorIndexOfPrompt);
            }
            final String _tmpTheme;
            if (_cursor.isNull(_cursorIndexOfTheme)) {
              _tmpTheme = null;
            } else {
              _tmpTheme = _cursor.getString(_cursorIndexOfTheme);
            }
            final String _tmpRequirement;
            if (_cursor.isNull(_cursorIndexOfRequirement)) {
              _tmpRequirement = null;
            } else {
              _tmpRequirement = _cursor.getString(_cursorIndexOfRequirement);
            }
            final Integer _tmpWordCount;
            if (_cursor.isNull(_cursorIndexOfWordCount)) {
              _tmpWordCount = null;
            } else {
              _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
            }
            final String _tmpStyle;
            if (_cursor.isNull(_cursorIndexOfStyle)) {
              _tmpStyle = null;
            } else {
              _tmpStyle = _cursor.getString(_cursorIndexOfStyle);
            }
            final String _tmpType;
            _tmpType = _cursor.getString(_cursorIndexOfType);
            final long _tmpCreateTime;
            _tmpCreateTime = _cursor.getLong(_cursorIndexOfCreateTime);
            final long _tmpUpdateTime;
            _tmpUpdateTime = _cursor.getLong(_cursorIndexOfUpdateTime);
            _item = new WritingRecord(_tmpId,_tmpTitle,_tmpContent,_tmpPrompt,_tmpTheme,_tmpRequirement,_tmpWordCount,_tmpStyle,_tmpType,_tmpCreateTime,_tmpUpdateTime);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getRecordById(final String id,
      final Continuation<? super WritingRecord> $completion) {
    final String _sql = "SELECT * FROM writing_records WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, id);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<WritingRecord>() {
      @Override
      @Nullable
      public WritingRecord call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfPrompt = CursorUtil.getColumnIndexOrThrow(_cursor, "prompt");
          final int _cursorIndexOfTheme = CursorUtil.getColumnIndexOrThrow(_cursor, "theme");
          final int _cursorIndexOfRequirement = CursorUtil.getColumnIndexOrThrow(_cursor, "requirement");
          final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
          final int _cursorIndexOfStyle = CursorUtil.getColumnIndexOrThrow(_cursor, "style");
          final int _cursorIndexOfType = CursorUtil.getColumnIndexOrThrow(_cursor, "type");
          final int _cursorIndexOfCreateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "createTime");
          final int _cursorIndexOfUpdateTime = CursorUtil.getColumnIndexOrThrow(_cursor, "updateTime");
          final WritingRecord _result;
          if (_cursor.moveToFirst()) {
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpContent;
            _tmpContent = _cursor.getString(_cursorIndexOfContent);
            final String _tmpPrompt;
            if (_cursor.isNull(_cursorIndexOfPrompt)) {
              _tmpPrompt = null;
            } else {
              _tmpPrompt = _cursor.getString(_cursorIndexOfPrompt);
            }
            final String _tmpTheme;
            if (_cursor.isNull(_cursorIndexOfTheme)) {
              _tmpTheme = null;
            } else {
              _tmpTheme = _cursor.getString(_cursorIndexOfTheme);
            }
            final String _tmpRequirement;
            if (_cursor.isNull(_cursorIndexOfRequirement)) {
              _tmpRequirement = null;
            } else {
              _tmpRequirement = _cursor.getString(_cursorIndexOfRequirement);
            }
            final Integer _tmpWordCount;
            if (_cursor.isNull(_cursorIndexOfWordCount)) {
              _tmpWordCount = null;
            } else {
              _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
            }
            final String _tmpStyle;
            if (_cursor.isNull(_cursorIndexOfStyle)) {
              _tmpStyle = null;
            } else {
              _tmpStyle = _cursor.getString(_cursorIndexOfStyle);
            }
            final String _tmpType;
            _tmpType = _cursor.getString(_cursorIndexOfType);
            final long _tmpCreateTime;
            _tmpCreateTime = _cursor.getLong(_cursorIndexOfCreateTime);
            final long _tmpUpdateTime;
            _tmpUpdateTime = _cursor.getLong(_cursorIndexOfUpdateTime);
            _result = new WritingRecord(_tmpId,_tmpTitle,_tmpContent,_tmpPrompt,_tmpTheme,_tmpRequirement,_tmpWordCount,_tmpStyle,_tmpType,_tmpCreateTime,_tmpUpdateTime);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
