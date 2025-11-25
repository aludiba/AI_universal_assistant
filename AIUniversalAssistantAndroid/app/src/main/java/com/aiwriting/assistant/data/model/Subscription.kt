package com.aiwriting.assistant.data.model

data class Subscription(
    val type: SubscriptionType,
    val expiryDate: Long? = null,
    val isActive: Boolean = false
)

enum class SubscriptionType(val displayName: String, val price: Double, val description: String) {
    NONE("未订阅", 0.0, ""),
    WEEKLY("周度会员", 6.0, "体验AI写作"),
    MONTHLY("月度会员", 18.0, "短期创作首选"),
    YEARLY("年度会员", 68.0, "约0.5毛/天"),
    LIFETIME("永久会员", 198.0, "一次购买，永久使用");

    fun isVIP(): Boolean = this != NONE
}

