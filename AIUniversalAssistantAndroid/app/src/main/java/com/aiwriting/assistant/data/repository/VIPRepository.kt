package com.aiwriting.assistant.data.repository

import android.content.Context
import com.aiwriting.assistant.data.model.Subscription
import com.aiwriting.assistant.data.model.SubscriptionType
import com.aiwriting.assistant.utils.PreferenceManager
import com.google.gson.Gson

class VIPRepository(context: Context) {
    private val preferenceManager = PreferenceManager(context)
    private val gson = Gson()

    // 检查是否是VIP
    fun isVIP(): Boolean {
        val subscription = getSubscription()
        return subscription.isActive && subscription.type.isVIP()
    }

    // 获取订阅信息
    fun getSubscription(): Subscription {
        val json = preferenceManager.getSubscription() ?: return Subscription(
            type = SubscriptionType.NONE,
            isActive = false
        )

        return try {
            gson.fromJson(json, Subscription::class.java)
        } catch (e: Exception) {
            Subscription(type = SubscriptionType.NONE, isActive = false)
        }
    }

    // 保存订阅信息
    fun saveSubscription(subscription: Subscription) {
        preferenceManager.saveSubscription(gson.toJson(subscription))
    }

    // 订阅会员
    fun subscribe(type: SubscriptionType) {
        val expiryDate = when (type) {
            SubscriptionType.WEEKLY -> System.currentTimeMillis() + 7 * 24 * 60 * 60 * 1000L
            SubscriptionType.MONTHLY -> System.currentTimeMillis() + 30 * 24 * 60 * 60 * 1000L
            SubscriptionType.YEARLY -> System.currentTimeMillis() + 365 * 24 * 60 * 60 * 1000L
            SubscriptionType.LIFETIME -> null
            SubscriptionType.NONE -> null
        }

        val subscription = Subscription(
            type = type,
            expiryDate = expiryDate,
            isActive = true
        )
        saveSubscription(subscription)
    }

    // 取消订阅
    fun cancelSubscription() {
        val subscription = Subscription(
            type = SubscriptionType.NONE,
            isActive = false
        )
        saveSubscription(subscription)
    }

    // 检查订阅是否过期
    fun checkSubscriptionExpiry(): Boolean {
        val subscription = getSubscription()
        if (!subscription.isActive) return false

        val expiryDate = subscription.expiryDate ?: return true // 永久会员

        val isExpired = System.currentTimeMillis() > expiryDate
        if (isExpired) {
            cancelSubscription()
        }
        return !isExpired
    }
}

