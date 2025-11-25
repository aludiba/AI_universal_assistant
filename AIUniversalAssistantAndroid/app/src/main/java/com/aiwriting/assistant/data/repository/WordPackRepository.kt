package com.aiwriting.assistant.data.repository

import android.content.Context
import com.aiwriting.assistant.data.model.*
import com.aiwriting.assistant.utils.PreferenceManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.text.SimpleDateFormat
import java.util.*

class WordPackRepository(context: Context) {
    private val preferenceManager = PreferenceManager(context)
    private val gson = Gson()

    companion object {
        const val VIP_DAILY_GIFT_WORDS = 500000 // 50万字
        const val WORD_PACK_VALID_DAYS = 90
    }

    // 获取VIP赠送字数
    suspend fun getVIPGiftedWords(isVIP: Boolean): Int {
        if (!isVIP) return 0

        val today = getTodayString()
        val lastRefreshDate = preferenceManager.getLastRefreshDate()

        // 如果不是今天，重置赠送字数
        if (lastRefreshDate != today) {
            refreshDailyGift()
            return VIP_DAILY_GIFT_WORDS
        }

        val giftJson = preferenceManager.getVIPGift() ?: run {
            refreshDailyGift()
            return VIP_DAILY_GIFT_WORDS
        }

        return try {
            val gift = gson.fromJson(giftJson, VIPGiftRecord::class.java)
            gift.remainingWords
        } catch (e: Exception) {
            refreshDailyGift()
            VIP_DAILY_GIFT_WORDS
        }
    }

    // 刷新VIP每日赠送
    private fun refreshDailyGift() {
        val today = System.currentTimeMillis()
        val gift = VIPGiftRecord(
            date = today,
            words = VIP_DAILY_GIFT_WORDS,
            remainingWords = VIP_DAILY_GIFT_WORDS
        )
        preferenceManager.saveVIPGift(gson.toJson(gift))
        preferenceManager.saveLastRefreshDate(getTodayString())
    }

    // 获取购买的字数包
    fun getPurchasedWordPacks(): List<WordPackRecord> {
        val json = preferenceManager.getWordPacks() ?: return emptyList()
        return try {
            val packs: List<WordPackRecord> = gson.fromJson(json, object : TypeToken<List<WordPackRecord>>() {}.type)
            packs.filter { !it.isExpired && it.remainingWords > 0 }
                .sortedBy { it.purchaseDate }
        } catch (e: Exception) {
            emptyList()
        }
    }

    // 购买字数包
    fun purchaseWordPack(type: WordPackType, words: Int) {
        val expiryDate = System.currentTimeMillis() + (WORD_PACK_VALID_DAYS * 24 * 60 * 60 * 1000L)
        val pack = WordPackRecord(
            id = UUID.randomUUID().toString(),
            type = type,
            words = words,
            purchaseDate = System.currentTimeMillis(),
            expiryDate = expiryDate,
            remainingWords = words,
            isExpired = false
        )

        val packs = getPurchasedWordPacks().toMutableList()
        packs.add(pack)
        saveWordPacks(packs)
    }

    // 消耗字数
    suspend fun consumeWords(words: Int, isVIP: Boolean): WordConsumeResult {
        if (words <= 0) {
            return WordConsumeResult(success = true, remainingWords = totalAvailableWords(isVIP))
        }

        var remaining = words

        // 优先消耗VIP赠送字数
        var vipGifted = getVIPGiftedWords(isVIP)
        if (vipGifted > 0) {
            val consumed = minOf(vipGifted, remaining)
            vipGifted -= consumed
            remaining -= consumed

            // 更新VIP赠送字数
            val gift = VIPGiftRecord(
                date = System.currentTimeMillis(),
                words = VIP_DAILY_GIFT_WORDS,
                remainingWords = vipGifted
            )
            preferenceManager.saveVIPGift(gson.toJson(gift))
        }

        // 如果还有剩余，消耗购买的字数包
        if (remaining > 0) {
            val packs = getPurchasedWordPacks().toMutableList()
            for (i in packs.indices) {
                if (packs[i].remainingWords > 0) {
                    val consumed = minOf(packs[i].remainingWords, remaining)
                    packs[i] = packs[i].copy(remainingWords = packs[i].remainingWords - consumed)
                    remaining -= consumed
                    if (remaining <= 0) break
                }
            }
            saveWordPacks(packs)
        }

        // 记录总消耗
        val totalConsumed = preferenceManager.getConsumedWords() + words
        preferenceManager.saveConsumedWords(totalConsumed)

        val totalRemaining = totalAvailableWords(isVIP)
        return WordConsumeResult(
            success = remaining <= 0,
            remainingWords = totalRemaining
        )
    }

    // 获取总可用字数
    suspend fun totalAvailableWords(isVIP: Boolean): Int {
        val vipGifted = getVIPGiftedWords(isVIP)
        val purchased = getPurchasedWordPacks().sumOf { it.remainingWords }
        return vipGifted + purchased
    }

    // 检查字数是否足够
    suspend fun hasEnoughWords(words: Int, isVIP: Boolean): Boolean {
        return totalAvailableWords(isVIP) >= words
    }

    // 字数统计
    fun countWordsInText(text: String): Int {
        return text.length
    }

    private fun saveWordPacks(packs: List<WordPackRecord>) {
        preferenceManager.saveWordPacks(gson.toJson(packs))
    }

    private fun getTodayString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }
}

