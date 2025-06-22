import 'package:uuid/uuid.dart';

/// Helper class for UUID generation
class UuidHelper {
  static const Uuid _uuid = Uuid();

  /// Generate a new UUID v4
  static String generateV4() {
    return _uuid.v4();
  }

  /// Generate a new UUID v1 (time-based)
  static String generateV1() {
    return _uuid.v1();
  }

  /// Generate a short UUID (8 characters)
  static String generateShort() {
    return _uuid.v4().substring(0, 8);
  }

  /// Validate UUID format
  static bool isValid(String uuid) {
    try {
      return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', 
                   caseSensitive: false).hasMatch(uuid);
    } catch (e) {
      return false;
    }
  }

  /// Generate device-specific UUID
  static String generateDeviceId() {
    // In a real app, this should be based on device characteristics
    // For now, generate a random UUID and store it persistently
    return generateV4();
  }

  /// Generate conversation ID
  static String generateConversationId(List<String> participantIds) {
    // Sort participant IDs to ensure consistent conversation ID
    final sortedIds = List<String>.from(participantIds)..sort();
    final combined = sortedIds.join('-');
    
    // Generate UUID v5 based on the combined participant IDs
    return _uuid.v5(Uuid.NAMESPACE_URL, combined);
  }

  /// Generate message ID
  static String generateMessageId() {
    return generateV4();
  }
}
