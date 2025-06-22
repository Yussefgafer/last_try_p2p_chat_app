import 'package:hive/hive.dart';

part 'group_model.g.dart';

/// Model for group chat data
@HiveType(typeId: 4)
class GroupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final List<String> memberIds;

  @HiveField(5)
  final List<String> adminIds;

  @HiveField(6)
  final String creatorId;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final GroupSettings settings;

  @HiveField(10)
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.memberIds,
    required this.adminIds,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    this.isActive = true,
  });

  /// Create GroupModel from JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      memberIds: List<String>.from(json['memberIds'] as List),
      adminIds: List<String>.from(json['adminIds'] as List),
      creatorId: json['creatorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      settings: GroupSettings.fromJson(json['settings'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert GroupModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'settings': settings.toJson(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? memberIds,
    List<String>? adminIds,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    GroupSettings? settings,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      adminIds: adminIds ?? List<String>.from(this.adminIds),
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is admin
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Check if user is creator
  bool isCreator(String userId) => creatorId == userId;

  /// Check if user can manage group
  bool canManageGroup(String userId) => isCreator(userId) || isAdmin(userId);

  /// Get display name
  String get displayName => name.isNotEmpty ? name : 'Group Chat';

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, members: ${memberIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.creatorId == creatorId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        imageUrl.hashCode ^
        creatorId.hashCode ^
        isActive.hashCode;
  }
}

/// Group settings model
@HiveType(typeId: 5)
class GroupSettings extends HiveObject {
  @HiveField(0)
  final bool allowMembersToAddOthers;

  @HiveField(1)
  final bool allowMembersToChangeInfo;

  @HiveField(2)
  final bool allowMembersToSendMessages;

  @HiveField(3)
  final bool allowMembersToSendMedia;

  @HiveField(4)
  final int maxMembers;

  @HiveField(5)
  final bool isPublic;

  @HiveField(6)
  final String? joinCode;

  GroupSettings({
    this.allowMembersToAddOthers = true,
    this.allowMembersToChangeInfo = false,
    this.allowMembersToSendMessages = true,
    this.allowMembersToSendMedia = true,
    this.maxMembers = 50,
    this.isPublic = false,
    this.joinCode,
  });

  /// Create GroupSettings from JSON
  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      allowMembersToAddOthers: json['allowMembersToAddOthers'] as bool? ?? true,
      allowMembersToChangeInfo: json['allowMembersToChangeInfo'] as bool? ?? false,
      allowMembersToSendMessages: json['allowMembersToSendMessages'] as bool? ?? true,
      allowMembersToSendMedia: json['allowMembersToSendMedia'] as bool? ?? true,
      maxMembers: json['maxMembers'] as int? ?? 50,
      isPublic: json['isPublic'] as bool? ?? false,
      joinCode: json['joinCode'] as String?,
    );
  }

  /// Convert GroupSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'allowMembersToAddOthers': allowMembersToAddOthers,
      'allowMembersToChangeInfo': allowMembersToChangeInfo,
      'allowMembersToSendMessages': allowMembersToSendMessages,
      'allowMembersToSendMedia': allowMembersToSendMedia,
      'maxMembers': maxMembers,
      'isPublic': isPublic,
      'joinCode': joinCode,
    };
  }

  /// Create a copy with updated fields
  GroupSettings copyWith({
    bool? allowMembersToAddOthers,
    bool? allowMembersToChangeInfo,
    bool? allowMembersToSendMessages,
    bool? allowMembersToSendMedia,
    int? maxMembers,
    bool? isPublic,
    String? joinCode,
  }) {
    return GroupSettings(
      allowMembersToAddOthers: allowMembersToAddOthers ?? this.allowMembersToAddOthers,
      allowMembersToChangeInfo: allowMembersToChangeInfo ?? this.allowMembersToChangeInfo,
      allowMembersToSendMessages: allowMembersToSendMessages ?? this.allowMembersToSendMessages,
      allowMembersToSendMedia: allowMembersToSendMedia ?? this.allowMembersToSendMedia,
      maxMembers: maxMembers ?? this.maxMembers,
      isPublic: isPublic ?? this.isPublic,
      joinCode: joinCode ?? this.joinCode,
    );
  }

  /// Get default settings
  static GroupSettings get defaultSettings => GroupSettings();

  @override
  String toString() {
    return 'GroupSettings(maxMembers: $maxMembers, isPublic: $isPublic)';
  }
}
