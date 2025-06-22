import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';

/// Service for communicating with Gemini 1.5 Flash API
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  /// Initialize the service
  void initialize() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.geminiApiUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));
  }

  /// Send a message to Gemini AI
  Future<String> sendMessage(String message, {String? customApiKey}) async {
    try {
      final apiKey = customApiKey ?? ApiConfig.getGeminiApiKey();
      
      if (!ApiConfig.isValidGeminiApiKey(apiKey)) {
        throw Exception('Invalid API key format');
      }

      final response = await _dio.post(
        '?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': message}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              return parts[0]['text'] as String;
            }
          }
        }
        throw Exception('Invalid response format from Gemini API');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _logger.e('Dio error: ${e.message}', error: e);
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          throw Exception('API Error: ${errorData['error']['message']}');
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('Unexpected error: $e', error: e);
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  /// Test API connection
  Future<bool> testConnection({String? customApiKey}) async {
    try {
      final response = await sendMessage('Hello', customApiKey: customApiKey);
      return response.isNotEmpty;
    } catch (e) {
      _logger.w('Connection test failed: $e');
      return false;
    }
  }

  /// Send message with conversation context
  Future<String> sendMessageWithContext(
    String message,
    List<Map<String, String>> conversationHistory, {
    String? customApiKey,
  }) async {
    try {
      final apiKey = customApiKey ?? ApiConfig.getGeminiApiKey();
      
      if (!ApiConfig.isValidGeminiApiKey(apiKey)) {
        throw Exception('Invalid API key format');
      }

      // Build conversation contents
      final contents = <Map<String, dynamic>>[];
      
      // Add conversation history
      for (final entry in conversationHistory) {
        if (entry['role'] == 'user') {
          contents.add({
            'parts': [{'text': entry['content']}],
            'role': 'user',
          });
        } else if (entry['role'] == 'assistant') {
          contents.add({
            'parts': [{'text': entry['content']}],
            'role': 'model',
          });
        }
      }
      
      // Add current message
      contents.add({
        'parts': [{'text': message}],
        'role': 'user',
      });

      final response = await _dio.post(
        '?key=$apiKey',
        data: {
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              return parts[0]['text'] as String;
            }
          }
        }
        throw Exception('Invalid response format from Gemini API');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error in sendMessageWithContext: $e', error: e);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
