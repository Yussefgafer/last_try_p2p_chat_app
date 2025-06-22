import 'package:hive/hive.dart';

part 'blocked_user_model.g.dart';

/// Model for blocked user data
@HiveType(typeId: 7)
class BlockedUserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String? reason;

  @HiveField(4)
  final String blockedBy;

  @HiveField(5)
  final DateTime blockedAt;

  @HiveField(6)
  final String? profileImageUrl;

  @HiveField(7)
  final bool isAutoBlocked;

  @HiveField(8)
  final Map<String, dynamic>? metadata;

  BlockedUserModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.reason,
    required this.blockedBy,
    required this.blockedAt,
    this.profileImageUrl,
    this.isAutoBlocked = false,
    this.metadata,
  });

  /// Create BlockedUserModel from JSON
  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      reason: json['reason'] as String?,
      blockedBy: json['blockedBy'] as String,
      blockedAt: DateTime.parse(json['blockedAt'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
      isAutoBlocked: json['isAutoBlocked'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert BlockedUserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'reason': reason,
      'blockedBy': blockedBy,
      'blockedAt': blockedAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'isAutoBlocked': isAutoBlocked,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  BlockedUserModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? reason,
    String? blockedBy,
    DateTime? blockedAt,
    String? profileImageUrl,
    bool? isAutoBlocked,
    Map<String, dynamic>? metadata,
  }) {
    return BlockedUserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      reason: reason ?? this.reason,
      blockedBy: blockedBy ?? this.blockedBy,
      blockedAt: blockedAt ?? this.blockedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAutoBlocked: isAutoBlocked ?? this.isAutoBlocked,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get display name
  String get displayName => userName.isNotEmpty ? userName : 'Unknown User';

  /// Get block duration in human readable format
  String get blockDuration {
    final now = DateTime.now();
    final difference = now.difference(blockedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Get formatted block date
  String get formattedBlockDate {
    return '${blockedAt.day}/${blockedAt.month}/${blockedAt.year}';
  }

  /// Get block reason or default
  String get displayReason => reason ?? 'No reason provided';

  /// Check if block is recent (within last 24 hours)
  bool get isRecentBlock {
    final now = DateTime.now();
    final difference = now.difference(blockedAt);
    return difference.inHours < 24;
  }

  /// Check if block is old (more than 30 days)
  bool get isOldBlock {
    final now = DateTime.now();
    final difference = now.difference(blockedAt);
    return difference.inDays > 30;
  }

  /// Get block type description
  String get blockTypeDescription {
    if (isAutoBlocked) {
      return 'Automatically blocked';
    } else {
      return 'Manually blocked';
    }
  }

  /// Get metadata value
  T? getMetadata<T>(String key) {
    if (metadata == null) return null;
    return metadata![key] as T?;
  }

  /// Set metadata value
  BlockedUserModel setMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata ?? {});
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Remove metadata value
  BlockedUserModel removeMetadata(String key) {
    if (metadata == null) return this;
    final newMetadata = Map<String, dynamic>.from(metadata!);
    newMetadata.remove(key);
    return copyWith(metadata: newMetadata);
  }

  @override
  String toString() {
    return 'BlockedUserModel(id: $id, userId: $userId, userName: $userName, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BlockedUserModel &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.reason == reason &&
        other.blockedBy == blockedBy &&
        other.blockedAt == blockedAt &&
        other.isAutoBlocked == isAutoBlocked;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        reason.hashCode ^
        blockedBy.hashCode ^
        blockedAt.hashCode ^
        isAutoBlocked.hashCode;
  }
}
