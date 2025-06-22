import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/uuid_helper.dart';

/// Service for managing user data and authentication
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Box<UserModel>? _userBox;
  SharedPreferences? _prefs;
  UserModel? _currentUser;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Register Hive adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      // Note: In a real app, you would generate these adapters using build_runner
      // For now, we'll handle this manually
    }
    
    _userBox = await Hive.openBox<UserModel>(AppConstants.userBox);
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return _prefs?.getBool('is_logged_in') ?? false;
  }

  /// Get current user
  UserModel? get currentUser => _currentUser;

  /// Get device ID
  String get deviceId {
    String? id = _prefs?.getString('device_id');
    if (id == null) {
      id = UuidHelper.generateDeviceId();
      _prefs?.setString('device_id', id);
    }
    return id;
  }

  /// Create or login user
  Future<UserModel> loginUser({
    required String name,
    String? profileImagePath,
    int? age,
    String? phoneNumber,
  }) async {
    final now = DateTime.now();
    final userId = UuidHelper.generateV4();
    
    final user = UserModel(
      id: userId,
      name: name,
      profileImagePath: profileImagePath,
      age: age,
      phoneNumber: phoneNumber,
      createdAt: now,
      lastSeen: now,
      isOnline: true,
      deviceId: deviceId,
    );

    // Save user to Hive
    await _userBox?.put(userId, user);
    
    // Save login state
    await _prefs?.setBool('is_logged_in', true);
    await _prefs?.setString('current_user_id', userId);
    
    _currentUser = user;
    return user;
  }

  /// Load current user from storage
  Future<UserModel?> loadCurrentUser() async {
    if (!isLoggedIn) return null;
    
    final userId = _prefs?.getString('current_user_id');
    if (userId == null) return null;
    
    _currentUser = _userBox?.get(userId);
    
    // Update last seen
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        lastSeen: DateTime.now(),
        isOnline: true,
      );
      await _userBox?.put(userId, _currentUser!);
    }
    
    return _currentUser;
  }

  /// Update user profile
  Future<UserModel?> updateUser({
    String? name,
    String? profileImagePath,
    int? age,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return null;
    
    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      profileImagePath: profileImagePath ?? _currentUser!.profileImagePath,
      age: age ?? _currentUser!.age,
      phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
    );
    
    await _userBox?.put(_currentUser!.id, _currentUser!);
    return _currentUser;
  }

  /// Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;
    
    _currentUser = _currentUser!.copyWith(
      isOnline: isOnline,
      lastSeen: DateTime.now(),
    );
    
    await _userBox?.put(_currentUser!.id, _currentUser!);
  }

  /// Logout user
  Future<void> logout() async {
    await updateOnlineStatus(false);
    await _prefs?.setBool('is_logged_in', false);
    await _prefs?.remove('current_user_id');
    _currentUser = null;
  }

  /// Get all users (for P2P discovery)
  List<UserModel> getAllUsers() {
    return _userBox?.values.toList() ?? [];
  }

  /// Add discovered user
  Future<void> addDiscoveredUser(UserModel user) async {
    await _userBox?.put(user.id, user);
  }

  /// Update user last seen
  Future<void> updateUserLastSeen(String userId) async {
    final user = _userBox?.get(userId);
    if (user != null) {
      final updatedUser = user.copyWith(lastSeen: DateTime.now());
      await _userBox?.put(userId, updatedUser);
    }
  }

  /// Check if user exists
  bool userExists(String userId) {
    return _userBox?.containsKey(userId) ?? false;
  }

  /// Get user by ID
  UserModel? getUserById(String userId) {
    return _userBox?.get(userId);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await updateOnlineStatus(false);
    await _userBox?.close();
  }
}
