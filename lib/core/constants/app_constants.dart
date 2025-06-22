/// App-wide constants and configuration
class AppConstants {
  // App Info
  static const String appName = 'P2P Chat';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  // Database
  static const String databaseName = 'p2p_chat.db';
  static const int databaseVersion = 1;

  // Hive Boxes
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String messagesBox = 'messages_box';

  // WebRTC Configuration
  static const Map<String, dynamic> rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // File Transfer Limits
  static const int maxFileSize = 20 * 1024 * 1024; // 20MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxAudioSize = 10 * 1024 * 1024; // 10MB

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeFile = 'file';
  static const String messageTypeLocation = 'location';

  // Connection Types
  static const String connectionTypeWebRTC = 'webrtc';
  static const String connectionTypeBluetooth = 'bluetooth';
  static const String connectionTypeLAN = 'lan';

  // Encryption
  static const String encryptionAlgorithm = 'AES';
  static const int encryptionKeyLength = 256;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
