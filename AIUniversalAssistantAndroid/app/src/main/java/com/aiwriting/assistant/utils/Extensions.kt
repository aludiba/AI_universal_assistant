package com.aiwriting.assistant.utils

import android.content.Context
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.*

// Toast 扩展
fun Context.toast(message: String, duration: Int = Toast.LENGTH_SHORT) {
    Toast.makeText(this, message, duration).show()
}

// 显示/隐藏软键盘
fun View.showKeyboard() {
    requestFocus()
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.showSoftInput(this, InputMethodManager.SHOW_IMPLICIT)
}

fun View.hideKeyboard() {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.hideSoftInputFromWindow(windowToken, 0)
}

// 日期格式化
fun Long.toDateString(pattern: String = "yyyy-MM-dd HH:mm"): String {
    val sdf = SimpleDateFormat(pattern, Locale.getDefault())
    return sdf.format(Date(this))
}

fun Long.toRelativeDateString(): String {
    val now = System.currentTimeMillis()
    val diff = now - this
    
    val calendar = Calendar.getInstance()
    calendar.timeInMillis = this
    val today = Calendar.getInstance()
    
    return when {
        calendar.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
        calendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) -> "今天"
        
        calendar.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
        calendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) - 1 -> "昨天"
        
        else -> this.toDateString("yyyy-MM-dd")
    }
}

// 字数格式化
fun Int.formatWords(): String {
    return when {
        this >= 10000 -> "${this / 10000}万"
        this >= 1000 -> "${this / 1000}千"
        else -> this.toString()
    }
}

// 文件大小格式化
fun Long.formatFileSize(): String {
    return when {
        this <= 0 -> "0 KB"
        this < 1024 -> "$this B"
        this < 1024 * 1024 -> String.format("%.1f KB", this / 1024.0)
        else -> String.format("%.1f MB", this / (1024.0 * 1024.0))
    }
}

// 字数统计
fun String.countWords(): Int {
    return this.length
}

// View 可见性扩展
fun View.visible() {
    visibility = View.VISIBLE
}

fun View.invisible() {
    visibility = View.INVISIBLE
}

fun View.gone() {
    visibility = View.GONE
}

fun View.isVisible(): Boolean = visibility == View.VISIBLE

