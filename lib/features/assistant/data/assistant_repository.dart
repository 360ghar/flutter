import 'dart:async';

import 'package:get/get.dart';

import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/sse_client.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/assistant/data/models/chat_message_model.dart';
import 'package:ghar360/features/assistant/data/models/conversation_model.dart';

class AssistantRepository {
  final SseClient _sseClient = Get.find<SseClient>();
  final ApiClient _apiClient = Get.find<ApiClient>();
  final Map<String, String?> _widgetHtmlCache = {};

  /// Stream chat response from the agent via SSE.
  Stream<SseEvent> streamChat({required String message, int? conversationId}) {
    return _sseClient.postStream(
      '/agent/chat',
      body: {'message': message, 'conversation_id': ?conversationId},
    );
  }

  /// List the user's conversations.
  Future<List<ConversationModel>> getConversations({int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiClient.get('/agent/conversations?limit=$limit&offset=$offset');
      if (response.body is List) {
        return (response.body as List)
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      DebugLogger.error('Failed to load conversations', e);
      return [];
    }
  }

  /// Get messages for a conversation.
  Future<List<ChatMessageModel>> getConversationMessages(
    int conversationId, {
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.get(
        '/agent/conversations/$conversationId/messages?limit=$limit',
      );
      if (response.body is List) {
        return (response.body as List)
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      DebugLogger.error('Failed to load messages', e);
      return [];
    }
  }

  /// Fetch widget HTML bundle by name (cached in memory).
  ///
  /// Caches both successful and failed results to avoid repeated
  /// network requests during streaming list rebuilds.
  Future<String?> getWidgetHtml(String widgetName) async {
    if (_widgetHtmlCache.containsKey(widgetName)) {
      return _widgetHtmlCache[widgetName];
    }
    try {
      final response = await _apiClient.get('/agent/widgets/$widgetName');
      if (response.body is String) {
        final html = response.body as String;
        _widgetHtmlCache[widgetName] = html;
        return html;
      }
    } catch (e) {
      DebugLogger.error('Failed to fetch widget HTML', e);
    }
    _widgetHtmlCache[widgetName] = null;
    return null;
  }

  /// Delete a conversation.
  Future<bool> deleteConversation(int conversationId) async {
    try {
      await _apiClient.delete('/agent/conversations/$conversationId');
      return true;
    } catch (e) {
      DebugLogger.error('Failed to delete conversation', e);
      return false;
    }
  }
}
