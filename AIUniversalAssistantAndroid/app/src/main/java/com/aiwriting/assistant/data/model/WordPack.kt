package com.aiwriting.assistant.data.model

data class WordPack(
    val type: WordPackType,
    val words: Int,
    val price: Double
)

enum class WordPackType(val displayName: String, val words: Int, val price: Double) {
    PACK_500K("50万字", 500000, 6.0),
    PACK_1M("100万字", 1000000, 12.0),
    PACK_3M("300万字", 3000000, 30.0),
    PACK_5M("500万字", 5000000, 50.0);

    fun toWordPack() = WordPack(this, words, price)
}

data class WordPackRecord(
    val id: String,
    val type: WordPackType,
    val words: Int,
    val purchaseDate: Long,
    val expiryDate: Long,
    val remainingWords: Int,
    val isExpired: Boolean
)

data class VIPGiftRecord(
    val date: Long,
    val words: Int,
    val remainingWords: Int
)

data class WordConsumeResult(
    val success: Boolean,
    val remainingWords: Int
)

