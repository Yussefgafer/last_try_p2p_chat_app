import 'package:hive/hive.dart';

part 'link_preview_model.g.dart';

/// Model for link preview data
@HiveType(typeId: 6)
class LinkPreviewModel extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final String? siteName;

  @HiveField(5)
  final String? faviconUrl;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final bool isValid;

  LinkPreviewModel({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.faviconUrl,
    required this.timestamp,
    this.isValid = true,
  });

  /// Create LinkPreviewModel from JSON
  factory LinkPreviewModel.fromJson(Map<String, dynamic> json) {
    return LinkPreviewModel(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      siteName: json['siteName'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isValid: json['isValid'] as bool? ?? true,
    );
  }

  /// Convert LinkPreviewModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'siteName': siteName,
      'faviconUrl': faviconUrl,
      'timestamp': timestamp.toIso8601String(),
      'isValid': isValid,
    };
  }

  /// Create a copy with updated fields
  LinkPreviewModel copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    String? faviconUrl,
    DateTime? timestamp,
    bool? isValid,
  }) {
    return LinkPreviewModel(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      siteName: siteName ?? this.siteName,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      timestamp: timestamp ?? this.timestamp,
      isValid: isValid ?? this.isValid,
    );
  }

  /// Get display title (title or site name or domain)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (siteName != null && siteName!.isNotEmpty) return siteName!;
    
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Get display description (truncated if too long)
  String? get displayDescription {
    if (description == null || description!.isEmpty) return null;
    
    if (description!.length > 150) {
      return '${description!.substring(0, 150)}...';
    }
    
    return description;
  }

  /// Get domain from URL
  String? get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Check if preview has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if preview has favicon
  bool get hasFavicon => faviconUrl != null && faviconUrl!.isNotEmpty;

  /// Check if preview has description
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Check if preview is complete (has title and either description or image)
  bool get isComplete {
    return title != null && 
           title!.isNotEmpty && 
           (hasDescription || hasImage);
  }

  /// Check if preview is expired (older than 24 hours)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours > 24;
  }

  /// Get age of preview in human readable format
  String get ageString {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
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

  /// Create empty/invalid preview
  static LinkPreviewModel empty(String url) {
    return LinkPreviewModel(
      url: url,
      timestamp: DateTime.now(),
      isValid: false,
    );
  }

  /// Create preview from minimal data
  static LinkPreviewModel minimal({
    required String url,
    String? title,
    String? description,
  }) {
    return LinkPreviewModel(
      url: url,
      title: title,
      description: description,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LinkPreviewModel(url: $url, title: $title, siteName: $siteName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LinkPreviewModel &&
        other.url == url &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.siteName == siteName &&
        other.faviconUrl == faviconUrl &&
        other.isValid == isValid;
  }

  @override
  int get hashCode {
    return url.hashCode ^
        title.hashCode ^
        description.hashCode ^
        imageUrl.hashCode ^
        siteName.hashCode ^
        faviconUrl.hashCode ^
        isValid.hashCode;
  }
}
