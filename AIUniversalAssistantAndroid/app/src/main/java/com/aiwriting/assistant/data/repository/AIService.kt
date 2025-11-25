package com.aiwriting.assistant.data.repository

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/**
 * AI服务 - 模拟DeepSeek API调用
 * 实际使用时需要接入真实的AI API
 */
class AIService {
    
    companion object {
        private const val API_KEY = "YOUR_DEEPSEEK_API_KEY"
        private const val API_URL = "https://api.deepseek.com/v1/chat/completions"
    }

    /**
     * 流式生成文本
     */
    fun generateStream(prompt: String, wordCount: Int? = null): Flow<String> = flow {
        // 模拟流式返回
        // 实际使用时应该调用真实的API
        val fullPrompt = buildPrompt(prompt, wordCount)
        val mockResponse = generateMockResponse(fullPrompt)
        
        // 模拟逐字返回
        for (char in mockResponse) {
            emit(char.toString())
            delay(20) // 模拟网络延迟
        }
    }

    /**
     * 一次性生成文本
     */
    suspend fun generate(prompt: String, wordCount: Int? = null): String {
        delay(1000) // 模拟网络延迟
        val fullPrompt = buildPrompt(prompt, wordCount)
        return generateMockResponse(fullPrompt)
    }

    /**
     * 续写
     */
    suspend fun continueWriting(content: String, style: String? = null): String {
        val prompt = buildContinuePrompt(content, style)
        return generate(prompt)
    }

    /**
     * 改写
     */
    suspend fun rewrite(content: String, style: String? = null): String {
        val prompt = buildRewritePrompt(content, style)
        return generate(prompt)
    }

    /**
     * 扩写
     */
    suspend fun expand(content: String, length: String, style: String): String {
        val prompt = buildExpandPrompt(content, length, style)
        return generate(prompt)
    }

    /**
     * 翻译
     */
    suspend fun translate(content: String, targetLanguage: String): String {
        val prompt = buildTranslatePrompt(content, targetLanguage)
        return generate(prompt)
    }

    private fun buildPrompt(prompt: String, wordCount: Int?): String {
        return if (wordCount != null && wordCount > 0) {
            "$prompt\n\n要求：生成约${wordCount}字的内容。"
        } else {
            prompt
        }
    }

    private fun buildContinuePrompt(content: String, style: String?): String {
        val styleText = if (style != null) "请使用${style}风格进行写作。" else ""
        return "请根据以下内容进行续写，保持原文风格和逻辑连贯性。$styleText\n\n$content"
    }

    private fun buildRewritePrompt(content: String, style: String?): String {
        val styleText = if (style != null) "请使用${style}风格进行改写。" else ""
        return "请对以下内容进行改写，保持原意但优化表达方式。$styleText\n\n$content"
    }

    private fun buildExpandPrompt(content: String, length: String, style: String): String {
        return "请对以下内容进行扩写，增加细节和丰富内容。请进行${length}长度的扩写，使用${style}风格。\n\n$content"
    }

    private fun buildTranslatePrompt(content: String, targetLanguage: String): String {
        return "请将以下内容翻译成${targetLanguage}，确保翻译准确流畅，保持原文意思不变。\n\n$content"
    }

    private fun generateMockResponse(prompt: String): String {
        // 这是一个模拟响应，实际使用时应该调用真实的API
        return """
            这是根据您的要求生成的内容。
            
            ${prompt.take(50)}...
            
            在实际应用中，这里会显示AI生成的完整内容。请配置DeepSeek API密钥以使用真实的AI生成功能。
            
            生成的内容会根据您的提示词和要求，创作出高质量的文章、文案或其他文本内容。
        """.trimIndent()
    }
}

