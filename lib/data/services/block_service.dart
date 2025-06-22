import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/blocked_user_model.dart';
import '../../core/utils/uuid_helper.dart';

/// Service for managing blocked users
class BlockService {
  static final BlockService _instance = BlockService._internal();
  factory BlockService() => _instance;
  BlockService._internal();

  final Logger _logger = Logger();
  
  Box<BlockedUserModel>? _blockedUsersBox;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _blockedUsersBox = await Hive.openBox<BlockedUserModel>('blocked_users');
      _isInitialized = true;
      _logger.i('Block service initialized');
    } catch (e) {
      _logger.e('Failed to initialize block service: $e');
      throw Exception('Block service initialization failed: $e');
    }
  }

  /// Block a user
  Future<bool> blockUser({
    required String userId,
    required String userName,
    String? reason,
    String? blockedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Check if user is already blocked
      if (await isUserBlocked(userId)) {
        _logger.w('User already blocked: $userId');
        return true;
      }

      final blockedUser = BlockedUserModel(
        id: UuidHelper.generateV4(),
        userId: userId,
        userName: userName,
        reason: reason,
        blockedBy: blockedBy ?? 'current_user',
        blockedAt: DateTime.now(),
      );

      await _blockedUsersBox?.put(userId, blockedUser);
      
      _logger.i('User blocked: $userName ($userId)');
      return true;
    } catch (e) {
      _logger.e('Failed to block user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      final blockedUser = await getBlockedUser(userId);
      if (blockedUser == null) {
        _logger.w('User not found in blocked list: $userId');
        return true;
      }

      await _blockedUsersBox?.delete(userId);
      
      _logger.i('User unblocked: ${blockedUser.userName} ($userId)');
      return true;
    } catch (e) {
      _logger.e('Failed to unblock user: $e');
      return false;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      return _blockedUsersBox?.containsKey(userId) ?? false;
    } catch (e) {
      _logger.e('Failed to check if user is blocked: $e');
      return false;
    }
  }

  /// Get blocked user details
  Future<BlockedUserModel?> getBlockedUser(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      return _blockedUsersBox?.get(userId);
    } catch (e) {
      _logger.e('Failed to get blocked user: $e');
      return null;
    }
  }

  /// Get all blocked users
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    if (!_isInitialized) await initialize();

    try {
      final blockedUsers = _blockedUsersBox?.values.toList() ?? [];
      
      // Sort by blocked date (newest first)
      blockedUsers.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
      
      return blockedUsers;
    } catch (e) {
      _logger.e('Failed to get blocked users: $e');
      return [];
    }
  }

  /// Get blocked users count
  Future<int> getBlockedUsersCount() async {
    if (!_isInitialized) await initialize();

    try {
      return _blockedUsersBox?.length ?? 0;
    } catch (e) {
      _logger.e('Failed to get blocked users count: $e');
      return 0;
    }
  }

  /// Block user with automatic reason detection
  Future<bool> blockUserWithReason({
    required String userId,
    required String userName,
    BlockReason reason = BlockReason.other,
    String? customReason,
    String? blockedBy,
  }) async {
    String reasonText;
    
    switch (reason) {
      case BlockReason.spam:
        reasonText = 'Spam messages';
        break;
      case BlockReason.harassment:
        reasonText = 'Harassment';
        break;
      case BlockReason.inappropriate:
        reasonText = 'Inappropriate content';
        break;
      case BlockReason.abuse:
        reasonText = 'Abusive behavior';
        break;
      case BlockReason.other:
        reasonText = customReason ?? 'Other';
        break;
    }

    return await blockUser(
      userId: userId,
      userName: userName,
      reason: reasonText,
      blockedBy: blockedBy,
    );
  }

  /// Check if message should be blocked
  Future<bool> shouldBlockMessage({
    required String senderId,
    required String messageContent,
  }) async {
    // Check if sender is blocked
    if (await isUserBlocked(senderId)) {
      return true;
    }

    // Additional content filtering can be added here
    // For example, checking for spam patterns, inappropriate content, etc.
    
    return false;
  }

  /// Filter blocked users from a list
  Future<List<String>> filterBlockedUsers(List<String> userIds) async {
    final filteredUsers = <String>[];
    
    for (final userId in userIds) {
      if (!await isUserBlocked(userId)) {
        filteredUsers.add(userId);
      }
    }
    
    return filteredUsers;
  }

  /// Get block statistics
  Future<Map<String, dynamic>> getBlockStatistics() async {
    try {
      final blockedUsers = await getBlockedUsers();
      final now = DateTime.now();
      
      // Count blocks by time period
      final today = blockedUsers.where((user) {
        final diff = now.difference(user.blockedAt);
        return diff.inDays == 0;
      }).length;
      
      final thisWeek = blockedUsers.where((user) {
        final diff = now.difference(user.blockedAt);
        return diff.inDays <= 7;
      }).length;
      
      final thisMonth = blockedUsers.where((user) {
        final diff = now.difference(user.blockedAt);
        return diff.inDays <= 30;
      }).length;

      // Count by reason
      final reasonCounts = <String, int>{};
      for (final user in blockedUsers) {
        final reason = user.reason ?? 'Unknown';
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }

      return {
        'total': blockedUsers.length,
        'today': today,
        'thisWeek': thisWeek,
        'thisMonth': thisMonth,
        'reasonCounts': reasonCounts,
      };
    } catch (e) {
      _logger.e('Failed to get block statistics: $e');
      return {};
    }
  }

  /// Clear all blocked users
  Future<bool> clearAllBlocks() async {
    if (!_isInitialized) await initialize();

    try {
      await _blockedUsersBox?.clear();
      _logger.i('All blocked users cleared');
      return true;
    } catch (e) {
      _logger.e('Failed to clear all blocks: $e');
      return false;
    }
  }

  /// Export blocked users list
  Future<List<Map<String, dynamic>>> exportBlockedUsers() async {
    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers.map((user) => user.toJson()).toList();
    } catch (e) {
      _logger.e('Failed to export blocked users: $e');
      return [];
    }
  }

  /// Import blocked users list
  Future<bool> importBlockedUsers(List<Map<String, dynamic>> data) async {
    if (!_isInitialized) await initialize();

    try {
      for (final userData in data) {
        final blockedUser = BlockedUserModel.fromJson(userData);
        await _blockedUsersBox?.put(blockedUser.userId, blockedUser);
      }
      
      _logger.i('Imported ${data.length} blocked users');
      return true;
    } catch (e) {
      _logger.e('Failed to import blocked users: $e');
      return false;
    }
  }

  /// Auto-block based on patterns
  Future<bool> autoBlock({
    required String userId,
    required String userName,
    required String content,
    required AutoBlockReason reason,
  }) async {
    String reasonText;
    
    switch (reason) {
      case AutoBlockReason.repeatedSpam:
        reasonText = 'Automatically blocked for repeated spam';
        break;
      case AutoBlockReason.suspiciousActivity:
        reasonText = 'Automatically blocked for suspicious activity';
        break;
      case AutoBlockReason.contentViolation:
        reasonText = 'Automatically blocked for content violation';
        break;
    }

    return await blockUser(
      userId: userId,
      userName: userName,
      reason: reasonText,
      blockedBy: 'auto_system',
    );
  }

  /// Dispose service
  Future<void> dispose() async {
    try {
      await _blockedUsersBox?.close();
      _isInitialized = false;
      _logger.i('Block service disposed');
    } catch (e) {
      _logger.e('Error disposing block service: $e');
    }
  }
}

/// Enum for block reasons
enum BlockReason {
  spam,
  harassment,
  inappropriate,
  abuse,
  other,
}

/// Enum for auto-block reasons
enum AutoBlockReason {
  repeatedSpam,
  suspiciousActivity,
  contentViolation,
}
