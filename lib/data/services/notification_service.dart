import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permission
      final permission = await Permission.notification.request();
      if (permission != PermissionStatus.granted) {
        _logger.w('Notification permission not granted');
        return;
      }

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      _logger.i('Notification service initialized');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.d('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to specific screen
    // This would typically use a navigation service
  }

  /// Show new message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? conversationId,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'messages',
        'Messages',
        channelDescription: 'New message notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _generateNotificationId(),
        senderName,
        message,
        details,
        payload: conversationId,
      );

      _logger.d('Message notification shown for $senderName');
    } catch (e) {
      _logger.e('Failed to show message notification: $e');
    }
  }

  /// Show connection notification
  Future<void> showConnectionNotification({
    required String peerName,
    required bool isConnected,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'connections',
        'Connections',
        channelDescription: 'P2P connection notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = isConnected ? 'Connected' : 'Disconnected';
      final body = isConnected 
          ? '$peerName is now connected'
          : '$peerName has disconnected';

      await _notifications.show(
        _generateNotificationId(),
        title,
        body,
        details,
      );

      _logger.d('Connection notification shown: $peerName - $isConnected');
    } catch (e) {
      _logger.e('Failed to show connection notification: $e');
    }
  }

  /// Show file received notification
  Future<void> showFileReceivedNotification({
    required String senderName,
    required String fileName,
    required String fileType,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'files',
        'File Sharing',
        channelDescription: 'File sharing notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _generateNotificationId(),
        'File Received',
        '$senderName sent you $fileName',
        details,
      );

      _logger.d('File notification shown: $fileName from $senderName');
    } catch (e) {
      _logger.e('Failed to show file notification: $e');
    }
  }

  /// Show AI response notification
  Future<void> showAIResponseNotification({
    required String response,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'ai_responses',
        'AI Assistant',
        channelDescription: 'AI assistant notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Truncate long responses
      final truncatedResponse = response.length > 100 
          ? '${response.substring(0, 100)}...'
          : response;

      await _notifications.show(
        _generateNotificationId(),
        'AI Assistant',
        truncatedResponse,
        details,
      );

      _logger.d('AI response notification shown');
    } catch (e) {
      _logger.e('Failed to show AI notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.d('All notifications cancelled');
    } catch (e) {
      _logger.e('Failed to cancel notifications: $e');
    }
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _logger.d('Notification $id cancelled');
    } catch (e) {
      _logger.e('Failed to cancel notification $id: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      _logger.e('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final permission = await Permission.notification.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      _logger.e('Failed to check notification permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      final permission = await Permission.notification.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      _logger.e('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  /// Dispose service
  void dispose() {
    _isInitialized = false;
    _logger.i('Notification service disposed');
  }
}
