import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// AI写作服务
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.deepSeekBaseUrl,
    connectTimeout: Duration(seconds: AppConfig.requestTimeout),
    receiveTimeout: Duration(seconds: AppConfig.requestTimeout),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConfig.deepSeekApiKey}',
    },
  ));

  CancelToken? _currentCancelToken;

  /// 生成写作内容（流式）
  Stream<String> generateStream({
    required String prompt,
    int? wordCount,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    _currentCancelToken = CancelToken();

    try {
      // 如果有字数要求，添加到prompt中
      String finalPrompt = prompt;
      if (wordCount != null && wordCount > 0) {
        finalPrompt = '$prompt\n\n请生成约$wordCount字的内容。';
      }

      // 估算token数
      int estimatedTokens = maxTokens ??
          _estimateTokensForWordCount(wordCount ?? 1000);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AppConfig.deepSeekModel,
          'messages': [
            {'role': 'user', 'content': finalPrompt}
          ],
          'stream': true,
          'temperature': temperature,
          'max_tokens': estimatedTokens,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
        cancelToken: _currentCancelToken,
      );

      final stream = response.data.stream;
      await for (var chunk in stream.transform(utf8.decoder)) {
        if (_currentCancelToken?.isCancelled ?? false) {
          break;
        }

        // 解析SSE格式的数据
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // 用户取消，不抛出错误
        return;
      }
      rethrow;
    } finally {
      _currentCancelToken = null;
    }
  }

  /// 生成写作内容（非流式）
  Future<String> generate({
    required String prompt,
    int? wordCount,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    String finalPrompt = prompt;
    if (wordCount != null && wordCount > 0) {
      finalPrompt = '$prompt\n\n请生成约$wordCount字的内容。';
    }

    int estimatedTokens = maxTokens ??
        _estimateTokensForWordCount(wordCount ?? 1000);

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AppConfig.deepSeekModel,
          'messages': [
            {'role': 'user', 'content': finalPrompt}
          ],
          'temperature': temperature,
          'max_tokens': estimatedTokens,
        },
      );

      return response.data['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('生成失败: ${e.toString()}');
    }
  }

  /// 多轮对话
  Future<String> generateWithMessages({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AppConfig.deepSeekModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens ?? 2000,
        },
      );

      return response.data['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('生成失败: ${e.toString()}');
    }
  }

  /// 取消当前请求
  void cancel() {
    _currentCancelToken?.cancel();
    _currentCancelToken = null;
  }

  /// 估算token数（基于字数）
  int _estimateTokensForWordCount(int wordCount) {
    // 中文大约1.5字符=1token，英文大约4字符=1token
    // 这里简单估算：平均2字符=1token
    return (wordCount * 2).clamp(100, 4000);
  }
}

