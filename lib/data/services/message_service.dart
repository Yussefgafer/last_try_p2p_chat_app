import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/uuid_helper.dart';
import '../../core/utils/encryption_helper.dart';

/// Service for managing messages and conversations locally
class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final Logger _logger = Logger();
  final EncryptionHelper _encryption = EncryptionHelper();

  Box<MessageModel>? _messagesBox;
  Box<ConversationModel>? _conversationsBox;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open Hive boxes
      _messagesBox = await Hive.openBox<MessageModel>(AppConstants.messagesBox);
      _conversationsBox = await Hive.openBox<ConversationModel>('conversations');
      
      _isInitialized = true;
      _logger.i('Message service initialized');
    } catch (e) {
      _logger.e('Failed to initialize message service: $e');
      throw Exception('Message service initialization failed: $e');
    }
  }

  /// Save a message
  Future<void> saveMessage(MessageModel message) async {
    if (!_isInitialized) await initialize();

    try {
      // Encrypt message content if needed
      MessageModel messageToSave = message;
      if (message.isEncrypted) {
        // In a real app, you'd use proper key management
        _encryption.initialize('default_key');
        final encryptedContent = _encryption.encryptText(message.content);
        messageToSave = message.copyWith(content: encryptedContent);
      }

      await _messagesBox?.put(message.id, messageToSave);
      
      // Update conversation
      await _updateConversation(message);
      
      _logger.d('Message saved: ${message.id}');
    } catch (e) {
      _logger.e('Failed to save message: $e');
      throw Exception('Failed to save message: $e');
    }
  }

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    if (!_isInitialized) await initialize();

    try {
      final allMessages = _messagesBox?.values.toList() ?? [];
      final conversationMessages = allMessages
          .where((msg) => msg.conversationId == conversationId)
          .toList();

      // Sort by timestamp
      conversationMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Decrypt messages if needed
      final decryptedMessages = <MessageModel>[];
      for (final message in conversationMessages) {
        if (message.isEncrypted) {
          try {
            _encryption.initialize('default_key');
            final decryptedContent = _encryption.decryptText(message.content);
            decryptedMessages.add(message.copyWith(content: decryptedContent));
          } catch (e) {
            _logger.w('Failed to decrypt message ${message.id}: $e');
            decryptedMessages.add(message);
          }
        } else {
          decryptedMessages.add(message);
        }
      }

      return decryptedMessages;
    } catch (e) {
      _logger.e('Failed to get messages: $e');
      return [];
    }
  }

  /// Update conversation with latest message
  Future<void> _updateConversation(MessageModel message) async {
    try {
      final conversationId = message.conversationId;
      ConversationModel? conversation = _conversationsBox?.get(conversationId);

      if (conversation == null) {
        // Create new conversation
        conversation = ConversationModel(
          id: conversationId,
          name: 'P2P Chat', // This should be set based on participants
          type: ConversationType.individual,
          participantIds: [message.senderId, message.receiverId],
          lastMessage: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          unreadCount: message.senderId != getCurrentUserId() ? 1 : 0,
        );
      } else {
        // Update existing conversation
        final isNewMessage = message.senderId != getCurrentUserId();
        conversation = conversation.copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
          unreadCount: isNewMessage 
              ? conversation.unreadCount + 1 
              : conversation.unreadCount,
        );
      }

      await _conversationsBox?.put(conversationId, conversation);
    } catch (e) {
      _logger.e('Failed to update conversation: $e');
    }
  }

  /// Get all conversations
  Future<List<ConversationModel>> getConversations() async {
    if (!_isInitialized) await initialize();

    try {
      final conversations = _conversationsBox?.values.toList() ?? [];
      
      // Sort by last update time
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return conversations;
    } catch (e) {
      _logger.e('Failed to get conversations: $e');
      return [];
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    if (!_isInitialized) await initialize();

    try {
      final conversation = _conversationsBox?.get(conversationId);
      if (conversation != null) {
        final updatedConversation = conversation.copyWith(unreadCount: 0);
        await _conversationsBox?.put(conversationId, updatedConversation);
      }
    } catch (e) {
      _logger.e('Failed to mark conversation as read: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (!_isInitialized) await initialize();

    try {
      await _messagesBox?.delete(messageId);
      _logger.d('Message deleted: $messageId');
    } catch (e) {
      _logger.e('Failed to delete message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    if (!_isInitialized) await initialize();

    try {
      // Delete all messages in the conversation
      final messages = await getMessages(conversationId);
      for (final message in messages) {
        await _messagesBox?.delete(message.id);
      }

      // Delete the conversation
      await _conversationsBox?.delete(conversationId);
      
      _logger.d('Conversation deleted: $conversationId');
    } catch (e) {
      _logger.e('Failed to delete conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Search messages
  Future<List<MessageModel>> searchMessages(String query) async {
    if (!_isInitialized) await initialize();

    try {
      final allMessages = _messagesBox?.values.toList() ?? [];
      final searchResults = allMessages
          .where((msg) => msg.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Sort by timestamp (newest first)
      searchResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return searchResults;
    } catch (e) {
      _logger.e('Failed to search messages: $e');
      return [];
    }
  }

  /// Get conversation by participants
  Future<ConversationModel?> getConversationByParticipants(List<String> participantIds) async {
    if (!_isInitialized) await initialize();

    try {
      final conversations = _conversationsBox?.values.toList() ?? [];
      
      for (final conversation in conversations) {
        if (conversation.participantIds.length == participantIds.length) {
          final sortedConvParticipants = List<String>.from(conversation.participantIds)..sort();
          final sortedInputParticipants = List<String>.from(participantIds)..sort();
          
          if (sortedConvParticipants.join(',') == sortedInputParticipants.join(',')) {
            return conversation;
          }
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('Failed to get conversation by participants: $e');
      return null;
    }
  }

  /// Create or get conversation
  Future<ConversationModel> createOrGetConversation({
    required List<String> participantIds,
    required String name,
    ConversationType type = ConversationType.individual,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Try to find existing conversation
      final existingConversation = await getConversationByParticipants(participantIds);
      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new conversation
      final conversationId = UuidHelper.generateConversationId(participantIds);
      final conversation = ConversationModel(
        id: conversationId,
        name: name,
        type: type,
        participantIds: participantIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _conversationsBox?.put(conversationId, conversation);
      return conversation;
    } catch (e) {
      _logger.e('Failed to create conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get message count for conversation
  Future<int> getMessageCount(String conversationId) async {
    if (!_isInitialized) await initialize();

    try {
      final messages = await getMessages(conversationId);
      return messages.length;
    } catch (e) {
      _logger.e('Failed to get message count: $e');
      return 0;
    }
  }

  /// Get unread message count
  Future<int> getTotalUnreadCount() async {
    if (!_isInitialized) await initialize();

    try {
      final conversations = await getConversations();
      return conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
    } catch (e) {
      _logger.e('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    if (!_isInitialized) await initialize();

    try {
      await _messagesBox?.clear();
      await _conversationsBox?.clear();
      _logger.i('All message data cleared');
    } catch (e) {
      _logger.e('Failed to clear data: $e');
      throw Exception('Failed to clear data: $e');
    }
  }

  /// Get current user ID (placeholder)
  String getCurrentUserId() {
    // This should return the current user's ID
    // For now, return a placeholder
    return 'current_user_id';
  }

  /// Dispose service
  Future<void> dispose() async {
    try {
      await _messagesBox?.close();
      await _conversationsBox?.close();
      _isInitialized = false;
      _logger.i('Message service disposed');
    } catch (e) {
      _logger.e('Error disposing message service: $e');
    }
  }
}
