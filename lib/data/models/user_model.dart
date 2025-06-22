import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? profileImagePath;

  @HiveField(3)
  final int? age;

  @HiveField(4)
  final String? phoneNumber;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastSeen;

  @HiveField(7)
  final bool isOnline;

  @HiveField(8)
  final String deviceId;

  UserModel({
    required this.id,
    required this.name,
    this.profileImagePath,
    this.age,
    this.phoneNumber,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    required this.deviceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImagePath: json['profileImagePath'] as String?,
      age: json['age'] as int?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      deviceId: json['deviceId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImagePath': profileImagePath,
      'age': age,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'deviceId': deviceId,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? profileImagePath,
    int? age,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? deviceId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Get display name
  String get displayName => name.isNotEmpty ? name : 'Unknown User';

  /// Check if user has profile image
  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.isNotEmpty;

  /// Get user initials for avatar
  String get initials {
    if (name.isEmpty) return 'U';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Check if user is active (last seen within 5 minutes)
  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes <= 5;
  }

  /// Get last seen text
  String get lastSeenText {
    if (isOnline) return 'Online';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, isOnline: $isOnline)';
  }
}
