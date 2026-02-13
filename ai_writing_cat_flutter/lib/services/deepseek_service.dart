import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// DeepSeek AI服务（对齐 iOS `AIUADeepSeekWriter` 能力）
class DeepSeekService {
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  http.Client? _currentClient;
  String _lineBuffer = '';

  String get _baseUrl => AppConfig.deepseekBaseUrl;
  String get _apiKey => AppConfig.deepseekApiKey;
  String get _modelName => AppConfig.deepseekModel;
  Duration get _timeout => AppConfig.apiTimeout;

  /// iOS 对齐：估算 token
  int estimatedTokensForWordCount(int wordCount) {
    return (wordCount * 1.5).ceil() + 50;
  }

  /// iOS 对齐：附加字数要求
  String addWordCountRequirementToPrompt(String prompt, int wordCount) {
    if (wordCount > 0) {
      return '$prompt\n\n请确保内容字数在$wordCount字左右。';
    }
    return prompt;
  }

  /// iOS 对齐：附加字数区间要求
  String addWordRangeRequirementToPrompt(String prompt, int minWords, int maxWords) {
    return '$prompt\n\n请确保内容字数在$minWords到$maxWords字之间。';
  }

  /// 生成文本（单次对话）
  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double temperature = 1.5,
  }) async {
    final messages = [
      {'role': 'user', 'content': prompt}
    ];

    return _makeRequest(
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// 生成指定字数的文本
  Future<String> generateTextWithWordCount({
    required String prompt,
    required int wordCount,
    double temperature = 1.5,
  }) async {
    final enhancedPrompt = addWordCountRequirementToPrompt(prompt, wordCount);
    final estimatedTokens = estimatedTokensForWordCount(wordCount);

    return generateText(
      prompt: enhancedPrompt,
      maxTokens: estimatedTokens,
      temperature: temperature,
    );
  }

  /// iOS 对齐：带字数区间的单次生成
  Future<String> generateTextWithWordRange({
    required String prompt,
    required int minWords,
    required int maxWords,
    double temperature = 1.5,
  }) async {
    final enhancedPrompt = addWordRangeRequirementToPrompt(prompt, minWords, maxWords);
    final estimatedTokens = estimatedTokensForWordCount(maxWords);
    return generateText(
      prompt: enhancedPrompt,
      maxTokens: estimatedTokens,
      temperature: temperature,
    );
  }

  /// 续写
  Future<String> continueWriting({
    required String content,
    String style = '通用',
  }) async {
    final prompt = '请根据以下内容进行续写，保持原文风格和逻辑连贯性。使用$style风格进行写作。\n\n$content';
    return generateText(prompt: prompt);
  }

  /// 改写
  Future<String> rewriteText({
    required String content,
    String style = '通用',
  }) async {
    final prompt = '请对以下内容进行改写，保持原意但优化表达方式。使用$style风格进行改写。\n\n$content';
    return generateText(prompt: prompt);
  }

  /// 扩写
  Future<String> expandText({
    required String content,
    String length = '适中',
    String style = '通用',
  }) async {
    final prompt = '请对以下内容进行扩写，增加细节和丰富内容。请进行$length长度的扩写，使用$style风格。\n\n$content';
    return generateText(prompt: prompt);
  }

  /// 翻译
  Future<String> translateText({
    required String content,
    required String targetLanguage,
  }) async {
    final prompt = '请将以下内容翻译成$targetLanguage，确保翻译准确流畅，保持原文意思不变。\n\n$content';
    return generateText(prompt: prompt);
  }

  /// iOS 对齐：完整流式生成（支持字数限制）
  Stream<String> generateFullStreamWritingWithPrompt({
    required String prompt,
    int wordCount = 0,
    double temperature = 1.5,
  }) {
    final finalPrompt = wordCount > 0 ? addWordCountRequirementToPrompt(prompt, wordCount) : prompt;
    final maxTokens = wordCount > 0 ? estimatedTokensForWordCount(wordCount) : 1000;
    return generateTextStream(
      prompt: finalPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// 流式生成文本
  Stream<String> generateTextStream({
    required String prompt,
    int? maxTokens,
    double temperature = 1.5,
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
    _lineBuffer = '';
  }

  /// 私有方法：发起请求
  Future<String> _makeRequest({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double temperature = 1.5,
  }) async {
    cancelCurrentRequest();
    _currentClient = http.Client();

    try {
      final response = await _currentClient!
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _modelName,
              'messages': messages,
              'max_tokens': (maxTokens ?? 1000).clamp(1, 4000),
              'temperature': temperature.clamp(0.0, 1.5),
              'stream': false,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = _extractContentFromResponse(data);
        if (content.isEmpty) {
          throw Exception('API返回为空');
        }
        return content.trim();
      } else {
        final body = utf8.decode(response.bodyBytes);
        try {
          final error = jsonDecode(body) as Map<String, dynamic>;
          throw Exception('API错误: ${error['error']?['message'] ?? '未知错误'}');
        } catch (_) {
          throw Exception('HTTP错误(${response.statusCode}): $body');
        }
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
    double temperature = 1.5,
  }) async* {
    cancelCurrentRequest();
    _currentClient = http.Client();
    _lineBuffer = '';

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });

      request.body = jsonEncode({
        'model': _modelName,
        'messages': messages,
        'max_tokens': (maxTokens ?? 1000).clamp(1, 4000),
        'temperature': temperature.clamp(0.0, 1.5),
        'stream': true,
      });

      final streamedResponse = await _currentClient!.send(request);

      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          _lineBuffer += chunk;
          final lines = _lineBuffer.split('\n');
          _lineBuffer = lines.removeLast();

          for (final rawLine in lines) {
            final line = rawLine.trim();
            if (!line.startsWith('data:')) continue;

            final data = line.substring(5).trim();
            if (data.isEmpty) continue;
            if (data == '[DONE]') return;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = _extractContentFromResponse(json);
              if (content.isNotEmpty) {
                yield content;
              }
            } catch (_) {
              // 忽略单条 SSE 解析错误，继续处理后续分片
            }
          }
        }
      } else {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception('流式请求失败(${streamedResponse.statusCode}): $body');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      throw Exception('流式生成失败: $e');
    } finally {
      _currentClient?.close();
      _currentClient = null;
      _lineBuffer = '';
    }
  }

  String _extractContentFromResponse(Map<String, dynamic> response) {
    final choices = response['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String) return content;
        }
        final delta = first['delta'];
        if (delta is Map<String, dynamic>) {
          final content = delta['content'];
          if (content is String) return content;
        }
      }
    }
    return '';
  }

  /// 计算文本字数
  int calculateWordCount(String text) {
    return text.length;
  }
}

