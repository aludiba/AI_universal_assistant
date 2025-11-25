class AIService {
  static const String apiKey = 'YOUR_DEEPSEEK_API_KEY';
  static const String apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  /// 流式生成文本
  Stream<String> generateStream({
    required String prompt,
    int? wordCount,
  }) async* {
    // 模拟流式返回
    final fullPrompt = _buildPrompt(prompt, wordCount);
    final mockResponse = _generateMockResponse(fullPrompt);
    
    // 模拟逐字返回
    for (int i = 0; i < mockResponse.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield mockResponse[i];
    }
  }

  /// 一次性生成文本
  Future<String> generate({
    required String prompt,
    int? wordCount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final fullPrompt = _buildPrompt(prompt, wordCount);
    return _generateMockResponse(fullPrompt);
  }

  /// 续写
  Future<String> continueWriting({
    required String content,
    String? style,
  }) async {
    final prompt = _buildContinuePrompt(content, style);
    return generate(prompt: prompt);
  }

  /// 改写
  Future<String> rewrite({
    required String content,
    String? style,
  }) async {
    final prompt = _buildRewritePrompt(content, style);
    return generate(prompt: prompt);
  }

  /// 扩写
  Future<String> expand({
    required String content,
    required String length,
    required String style,
  }) async {
    final prompt = _buildExpandPrompt(content, length, style);
    return generate(prompt: prompt);
  }

  /// 翻译
  Future<String> translate({
    required String content,
    required String targetLanguage,
  }) async {
    final prompt = _buildTranslatePrompt(content, targetLanguage);
    return generate(prompt: prompt);
  }

  String _buildPrompt(String prompt, int? wordCount) {
    if (wordCount != null && wordCount > 0) {
      return '$prompt\n\n要求：生成约$wordCount字的内容。';
    }
    return prompt;
  }

  String _buildContinuePrompt(String content, String? style) {
    final styleText = style != null ? '请使用$style风格进行写作。' : '';
    return '请根据以下内容进行续写，保持原文风格和逻辑连贯性。$styleText\n\n$content';
  }

  String _buildRewritePrompt(String content, String? style) {
    final styleText = style != null ? '请使用$style风格进行改写。' : '';
    return '请对以下内容进行改写，保持原意但优化表达方式。$styleText\n\n$content';
  }

  String _buildExpandPrompt(String content, String length, String style) {
    return '请对以下内容进行扩写，增加细节和丰富内容。请进行$length长度的扩写，使用$style风格。\n\n$content';
  }

  String _buildTranslatePrompt(String content, String targetLanguage) {
    return '请将以下内容翻译成$targetLanguage，确保翻译准确流畅，保持原文意思不变。\n\n$content';
  }

  String _generateMockResponse(String prompt) {
    return '''
这是根据您的要求生成的内容。

${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...

在实际应用中，这里会显示AI生成的完整内容。请配置DeepSeek API密钥以使用真实的AI生成功能。

生成的内容会根据您的提示词和要求，创作出高质量的文章、文案或其他文本内容。
    '''.trim();
  }
}

