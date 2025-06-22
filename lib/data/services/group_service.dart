import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../../core/utils/uuid_helper.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing group chats
class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final Logger _logger = Logger();
  
  Box<GroupModel>? _groupsBox;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _groupsBox = await Hive.openBox<GroupModel>('groups');
      _isInitialized = true;
      _logger.i('Group service initialized');
    } catch (e) {
      _logger.e('Failed to initialize group service: $e');
      throw Exception('Group service initialization failed: $e');
    }
  }

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    required String creatorId,
    List<String>? initialMemberIds,
    GroupSettings? settings,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final groupId = UuidHelper.generateV4();
      final now = DateTime.now();
      
      // Ensure creator is in member and admin lists
      final memberIds = <String>{creatorId};
      if (initialMemberIds != null) {
        memberIds.addAll(initialMemberIds);
      }

      final group = GroupModel(
        id: groupId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        memberIds: memberIds.toList(),
        adminIds: [creatorId],
        creatorId: creatorId,
        createdAt: now,
        updatedAt: now,
        settings: settings ?? GroupSettings.defaultSettings,
      );

      await _groupsBox?.put(groupId, group);
      
      _logger.i('Group created: $name ($groupId)');
      return group;
    } catch (e) {
      _logger.e('Failed to create group: $e');
      throw Exception('Failed to create group: $e');
    }
  }

  /// Get all groups for a user
  Future<List<GroupModel>> getUserGroups(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      final allGroups = _groupsBox?.values.toList() ?? [];
      final userGroups = allGroups
          .where((group) => group.isMember(userId) && group.isActive)
          .toList();

      // Sort by last updated
      userGroups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return userGroups;
    } catch (e) {
      _logger.e('Failed to get user groups: $e');
      return [];
    }
  }

  /// Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    if (!_isInitialized) await initialize();

    try {
      return _groupsBox?.get(groupId);
    } catch (e) {
      _logger.e('Failed to get group: $e');
      return null;
    }
  }

  /// Update group information
  Future<GroupModel?> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
    GroupSettings? settings,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return null;

      final updatedGroup = group.copyWith(
        name: name,
        description: description,
        imageUrl: imageUrl,
        settings: settings,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Group updated: $groupId');
      return updatedGroup;
    } catch (e) {
      _logger.e('Failed to update group: $e');
      return null;
    }
  }

  /// Add member to group
  Future<bool> addMember({
    required String groupId,
    required String userId,
    required String addedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Check permissions
      if (!group.canManageGroup(addedBy) && !group.settings.allowMembersToAddOthers) {
        throw Exception('No permission to add members');
      }

      // Check if already a member
      if (group.isMember(userId)) {
        return true; // Already a member
      }

      // Check member limit
      if (group.memberIds.length >= group.settings.maxMembers) {
        throw Exception('Group is full');
      }

      final updatedMemberIds = List<String>.from(group.memberIds)..add(userId);
      final updatedGroup = group.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Member added to group: $userId -> $groupId');
      return true;
    } catch (e) {
      _logger.e('Failed to add member: $e');
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMember({
    required String groupId,
    required String userId,
    required String removedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Check permissions (admins can remove anyone, users can only remove themselves)
      if (!group.canManageGroup(removedBy) && removedBy != userId) {
        throw Exception('No permission to remove this member');
      }

      // Cannot remove creator
      if (group.isCreator(userId)) {
        throw Exception('Cannot remove group creator');
      }

      // Remove from members and admins
      final updatedMemberIds = List<String>.from(group.memberIds)..remove(userId);
      final updatedAdminIds = List<String>.from(group.adminIds)..remove(userId);

      final updatedGroup = group.copyWith(
        memberIds: updatedMemberIds,
        adminIds: updatedAdminIds,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Member removed from group: $userId -> $groupId');
      return true;
    } catch (e) {
      _logger.e('Failed to remove member: $e');
      return false;
    }
  }

  /// Promote member to admin
  Future<bool> promoteToAdmin({
    required String groupId,
    required String userId,
    required String promotedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Only creator can promote to admin
      if (!group.isCreator(promotedBy)) {
        throw Exception('Only group creator can promote admins');
      }

      // Check if user is a member
      if (!group.isMember(userId)) {
        throw Exception('User is not a member of this group');
      }

      // Check if already an admin
      if (group.isAdmin(userId)) {
        return true; // Already an admin
      }

      final updatedAdminIds = List<String>.from(group.adminIds)..add(userId);
      final updatedGroup = group.copyWith(
        adminIds: updatedAdminIds,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Member promoted to admin: $userId -> $groupId');
      return true;
    } catch (e) {
      _logger.e('Failed to promote member: $e');
      return false;
    }
  }

  /// Demote admin to member
  Future<bool> demoteAdmin({
    required String groupId,
    required String userId,
    required String demotedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Only creator can demote admins
      if (!group.isCreator(demotedBy)) {
        throw Exception('Only group creator can demote admins');
      }

      // Cannot demote creator
      if (group.isCreator(userId)) {
        throw Exception('Cannot demote group creator');
      }

      final updatedAdminIds = List<String>.from(group.adminIds)..remove(userId);
      final updatedGroup = group.copyWith(
        adminIds: updatedAdminIds,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Admin demoted to member: $userId -> $groupId');
      return true;
    } catch (e) {
      _logger.e('Failed to demote admin: $e');
      return false;
    }
  }

  /// Delete group
  Future<bool> deleteGroup({
    required String groupId,
    required String deletedBy,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Only creator can delete group
      if (!group.isCreator(deletedBy)) {
        throw Exception('Only group creator can delete the group');
      }

      // Mark as inactive instead of deleting
      final updatedGroup = group.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Group deleted: $groupId');
      return true;
    } catch (e) {
      _logger.e('Failed to delete group: $e');
      return false;
    }
  }

  /// Generate join code for group
  Future<String?> generateJoinCode(String groupId) async {
    if (!_isInitialized) await initialize();

    try {
      final group = await getGroup(groupId);
      if (group == null) return null;

      final joinCode = UuidHelper.generateShort();
      final updatedSettings = group.settings.copyWith(joinCode: joinCode);
      final updatedGroup = group.copyWith(
        settings: updatedSettings,
        updatedAt: DateTime.now(),
      );

      await _groupsBox?.put(groupId, updatedGroup);
      
      _logger.d('Join code generated for group: $groupId');
      return joinCode;
    } catch (e) {
      _logger.e('Failed to generate join code: $e');
      return null;
    }
  }

  /// Join group by code
  Future<GroupModel?> joinGroupByCode({
    required String joinCode,
    required String userId,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final allGroups = _groupsBox?.values.toList() ?? [];
      final group = allGroups.firstWhere(
        (g) => g.settings.joinCode == joinCode && g.isActive,
        orElse: () => throw Exception('Invalid join code'),
      );

      // Add user to group
      final success = await addMember(
        groupId: group.id,
        userId: userId,
        addedBy: userId, // Self-join
      );

      if (success) {
        return await getGroup(group.id);
      }
      
      return null;
    } catch (e) {
      _logger.e('Failed to join group by code: $e');
      return null;
    }
  }

  /// Get group member count
  Future<int> getMemberCount(String groupId) async {
    final group = await getGroup(groupId);
    return group?.memberCount ?? 0;
  }

  /// Check if user can send messages
  bool canSendMessages(GroupModel group, String userId) {
    if (!group.isMember(userId)) return false;
    if (group.canManageGroup(userId)) return true;
    return group.settings.allowMembersToSendMessages;
  }

  /// Check if user can send media
  bool canSendMedia(GroupModel group, String userId) {
    if (!group.isMember(userId)) return false;
    if (group.canManageGroup(userId)) return true;
    return group.settings.allowMembersToSendMedia;
  }

  /// Dispose service
  Future<void> dispose() async {
    try {
      await _groupsBox?.close();
      _isInitialized = false;
      _logger.i('Group service disposed');
    } catch (e) {
      _logger.e('Error disposing group service: $e');
    }
  }
}
