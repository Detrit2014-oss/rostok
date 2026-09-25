import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// Настройки подключения к LLM.
class LlmConfig {
  LlmConfig({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
  });

  String baseUrl;
  String apiKey;
  String model;

  bool get isConfigured => apiKey.trim().isNotEmpty;
}

/// Реальный LLM для дневника настроения — любой API, совместимый с
/// OpenAI Chat Completions: OpenAI, OpenRouter, Groq, локальный прокси.
///
/// Ключ вводится пользователем в Профиле и хранится только на устройстве.
/// Для коммерческого релиза рекомендуем прокси-бэкенд, чтобы ключ не
/// оказался в сборке приложения (см. README, раздел «Безопасность»).
class LlmService {
  LlmService(this._storage);

  final StorageService _storage;
  LlmConfig config = LlmConfig();

  static const String _kBaseUrl = 'llm_base_url';
  static const String _kApiKey = 'llm_api_key';
  static const String _kModel = 'llm_model';

  /// Системный промпт ИИ-садовника.
  static const String kDiarySystemPrompt =
      'Ты — тёплый и заботливый ИИ-садовник приложения «Росток» '
      'о цифровой гигиене и ментальном здоровье. Пользователь вечером пишет '
      'короткую заметку о своём дне. Ответь на русском: 2–4 предложения. '
      'Поддержи человека, мягко отрази его чувства без осуждения и дай одну '
      'практичную рекомендацию для улучшения сна или снижения стресса. '
      'Без диагнозов, без канцелярита, обращение на «вы».';

  void load() {
    config = LlmConfig(
      baseUrl: _storage.getString(_kBaseUrl,
          defaultValue: 'https://api.openai.com/v1'),
      apiKey: _storage.getString(_kApiKey),
      model:
          _storage.getString(_kModel, defaultValue: 'gpt-4o-mini'),
    );
  }

  void saveConfig({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) {
    config = LlmConfig(
      baseUrl: baseUrl.trim().isEmpty
          ? 'https://api.openai.com/v1'
          : baseUrl.trim(),
      apiKey: apiKey.trim(),
      model:
          model.trim().isEmpty ? 'gpt-4o-mini' : model.trim(),
    );
    _storage.setString(_kBaseUrl, config.baseUrl);
    _storage.setString(_kApiKey, config.apiKey);
    _storage.setString(_kModel, config.model);
  }

  /// Базовый вызов chat/completions. Возвращает текст ответа или null
  /// (не настроено / ошибка сети / ошибка API — вызывающий код умеет
  /// gracefully деградировать до офлайн-анализа).
  Future<String?> chat(List<Map<String, String>> messages) async {
    if (!config.isConfigured) return null;

    final String base =
        config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final Uri uri = Uri.parse('$base/chat/completions');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode(<String, dynamic>{
              'model': config.model,
              'messages': messages,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final dynamic choices = data['choices'];
          if (choices is List && choices.isNotEmpty) {
            final dynamic first = choices.first;
            if (first is Map<String, dynamic>) {
              final dynamic message = first['message'];
              if (message is Map<String, dynamic>) {
                final dynamic content = message['content'];
                if (content is String) return content;
              }
            }
          }
        }
      }
    } catch (_) {
      // Нет сети, неверный ключ, недоступный прокси — молча возвращаем null.
      return null;
    }
    return null;
  }

  /// Ответ ИИ-садовника на вечернюю запись дневника.
  Future<String?> diaryReply(String text) => chat(<Map<String, String>>[
        <String, String>{'role': 'system', 'content': kDiarySystemPrompt},
        <String, String>{'role': 'user', 'content': text},
      ]);
}
