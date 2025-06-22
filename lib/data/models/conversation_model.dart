import 'package:hive/hive.dart';
import 'message_model.dart';

part 'conversation_model.g.dart';

@HiveType(typeId: 4)
class ConversationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ConversationType type;

  @HiveField(3)
  final List<String> participantIds;

  @HiveField(4)
  final MessageModel? lastMessage;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final int unreadCount;

  @HiveField(8)
  final bool isMuted;

  @HiveField(9)
  final String? avatarPath;

  @HiveField(10)
  final Map<String, dynamic>? metadata;

  ConversationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.avatarPath,
    this.metadata,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ConversationType.values[json['type'] as int],
      participantIds: List<String>.from(json['participantIds'] as List),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
      avatarPath: json['avatarPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'avatarPath': avatarPath,
      'metadata': metadata,
    };
  }

  ConversationModel copyWith({
    String? id,
    String? name,
    ConversationType? type,
    List<String>? participantIds,
    MessageModel? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isMuted,
    String? avatarPath,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      avatarPath: avatarPath ?? this.avatarPath,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Get display name for conversation
  String get displayName {
    if (name.isNotEmpty) return name;

    switch (type) {
      case ConversationType.individual:
        return 'Direct Chat';
      case ConversationType.group:
        return 'Group Chat';
      case ConversationType.ai:
        return 'AI Assistant';
    }
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if conversation has avatar
  bool get hasAvatar => avatarPath != null && avatarPath!.isNotEmpty;

  /// Get participant count
  int get participantCount => participantIds.length;

  /// Check if conversation is group
  bool get isGroup => type == ConversationType.group;

  /// Check if conversation is individual
  bool get isIndividual => type == ConversationType.individual;

  /// Check if conversation is AI
  bool get isAI => type == ConversationType.ai;

  /// Get formatted last message time
  String get formattedLastMessageTime {
    if (lastMessage?.timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastMessage!.timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[lastMessage!.timestamp.weekday - 1];
    } else {
      return '${lastMessage!.timestamp.day}/${lastMessage!.timestamp.month}';
    }
  }

  /// Get last message preview
  String get lastMessagePreview {
    if (lastMessage == null) {
      return 'No messages yet';
    }

    return lastMessage!.previewText;
  }

  /// Check if user is participant
  bool isParticipant(String userId) => participantIds.contains(userId);

  /// Mark as read
  ConversationModel markAsRead() {
    return copyWith(unreadCount: 0);
  }

  /// Increment unread count
  ConversationModel incrementUnreadCount() {
    return copyWith(unreadCount: unreadCount + 1);
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, name: $name, type: $type)';
  }
}

@HiveType(typeId: 5)
enum ConversationType {
  @HiveField(0)
  individual,
  @HiveField(1)
  group,
  @HiveField(2)
  ai,
}
