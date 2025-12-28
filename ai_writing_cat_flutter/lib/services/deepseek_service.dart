import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// DeepSeek AI服务
class DeepSeekService {
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();
  
  http.Client? _currentClient;
  
  /// 生成文本（单次对话）
  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double temperature = 0.7,
  }) async {
    final messages = [
      {'role': 'user', 'content': prompt}
    ];
    
    return await _makeRequest(
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
  
  /// 生成指定字数的文本
  Future<String> generateTextWithWordCount({
    required String prompt,
    required int wordCount,
  }) async {
    final enhancedPrompt = '$prompt\n\n请生成约$wordCount字的内容。';
    final estimatedTokens = _estimateTokens(wordCount);
    
    return await generateText(
      prompt: enhancedPrompt,
      maxTokens: estimatedTokens,
    );
  }
  
  /// 续写
  Future<String> continueWriting({
    required String content,
    String style = '通用',
  }) async {
    final prompt = '请根据以下内容进行续写，保持原文风格和逻辑连贯性。使用$style风格进行写作。\n\n$content';
    return await generateText(prompt: prompt);
  }
  
  /// 改写
  Future<String> rewriteText({
    required String content,
    String style = '通用',
  }) async {
    final prompt = '请对以下内容进行改写，保持原意但优化表达方式。使用$style风格进行改写。\n\n$content';
    return await generateText(prompt: prompt);
  }
  
  /// 扩写
  Future<String> expandText({
    required String content,
    String length = '适中',
    String style = '通用',
  }) async {
    final prompt = '请对以下内容进行扩写，增加细节和丰富内容。请进行$length长度的扩写，使用$style风格。\n\n$content';
    return await generateText(prompt: prompt);
  }
  
  /// 翻译
  Future<String> translateText({
    required String content,
    required String targetLanguage,
  }) async {
    final prompt = '请将以下内容翻译成$targetLanguage，确保翻译准确流畅，保持原文意思不变。\n\n$content';
    return await generateText(prompt: prompt);
  }
  
  /// 流式生成文本
  Stream<String> generateTextStream({
    required String prompt,
    int? maxTokens,
    double temperature = 0.7,
  }) async* {
    final messages = [
      {'role': 'user', 'content': prompt}
    ];
    
    yield* _makeStreamRequest(
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
  
  /// 取消当前请求
  void cancelCurrentRequest() {
    _currentClient?.close();
    _currentClient = null;
  }
  
  /// 私有方法：发起请求
  Future<String> _makeRequest({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double temperature = 0.7,
  }) async {
    _currentClient = http.Client();
    
    try {
      final response = await _currentClient!
          .post(
            Uri.parse('${AppConfig.deepseekBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.deepseekApiKey}',
            },
            body: jsonEncode({
              'model': AppConfig.deepseekModel,
              'messages': messages,
              'temperature': temperature,
              if (maxTokens != null) 'max_tokens': maxTokens,
            }),
          )
          .timeout(AppConfig.apiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('API错误: ${error['error']['message'] ?? '未知错误'}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      throw Exception('生成失败: $e');
    } finally {
      _currentClient = null;
    }
  }
  
  /// 私有方法：流式请求
  Stream<String> _makeStreamRequest({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double temperature = 0.7,
  }) async* {
    _currentClient = http.Client();
    
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppConfig.deepseekBaseUrl}/chat/completions'),
      );
      
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.deepseekApiKey}',
      });
      
      request.body = jsonEncode({
        'model': AppConfig.deepseekModel,
        'messages': messages,
        'temperature': temperature,
        'stream': true,
        if (maxTokens != null) 'max_tokens': maxTokens,
      });
      
      final streamedResponse = await _currentClient!.send(request);
      
      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') continue;
              if (data.isEmpty) continue;
              
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                final delta = json['choices']?[0]?['delta'];
                if (delta != null && delta['content'] != null) {
                  yield delta['content'] as String;
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        }
      } else {
        throw Exception('流式请求失败: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('流式生成失败: $e');
    } finally {
      _currentClient = null;
    }
  }
  
  /// 估算tokens数量（中文大约1.5个字符=1 token）
  int _estimateTokens(int wordCount) {
    return (wordCount * 1.5).ceil() + 500; // 添加缓冲
  }
  
  /// 计算文本字数
  int calculateWordCount(String text) {
    return text.length;
  }
}

