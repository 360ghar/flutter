enum ChatRole { user, assistant, toolCall, toolResult, error, widget }

class ChatMessageModel {
  final String id;
  final ChatRole role;
  final String content;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final Map<String, dynamic>? toolResult;
  final String? widgetName;
  final Map<String, dynamic>? widgetData;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.widgetName,
    this.widgetData,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessageModel copyWith({
    String? content,
    bool? isStreaming,
    Map<String, dynamic>? toolResult,
    String? widgetName,
    Map<String, dynamic>? widgetData,
  }) {
    return ChatMessageModel(
      id: id,
      role: role,
      content: content ?? this.content,
      toolName: toolName,
      toolArgs: toolArgs,
      toolResult: toolResult ?? this.toolResult,
      widgetName: widgetName ?? this.widgetName,
      widgetData: widgetData ?? this.widgetData,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      role: _parseRole(json['role'] as String?),
      content: json['content'] as String? ?? '',
      toolName: json['tool_name'] as String?,
      toolArgs: json['tool_args'] as Map<String, dynamic>?,
      toolResult: json['tool_result'] as Map<String, dynamic>?,
      widgetName: json['widget_name'] as String?,
      widgetData: json['widget_data'] as Map<String, dynamic>?,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static ChatRole _parseRole(String? role) {
    switch (role) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      case 'tool_call':
        return ChatRole.toolCall;
      case 'tool_result':
        return ChatRole.toolResult;
      case 'widget':
        return ChatRole.widget;
      default:
        return ChatRole.assistant;
    }
  }
}
