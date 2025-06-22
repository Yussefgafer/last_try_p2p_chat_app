import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:logger/logger.dart';
import '../../core/utils/uuid_helper.dart';

/// Service for Bluetooth P2P communication
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final Logger _logger = Logger();
  
  BluetoothConnection? _connection;
  String? _localDeviceId;
  String? _connectedDeviceId;
  
  // Callbacks
  Function(String message)? onMessageReceived;
  Function(String deviceId)? onDeviceConnected;
  Function(String deviceId)? onDeviceDisconnected;
  Function(bool isConnected)? onConnectionStateChanged;

  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize Bluetooth service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _localDeviceId = UuidHelper.generateDeviceId();
      
      // Check if Bluetooth is available
      final isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
      if (!isAvailable) {
        throw Exception('Bluetooth is not available on this device');
      }

      // Check if Bluetooth is enabled
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        // Request to enable Bluetooth
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      _isInitialized = true;
      _logger.i('Bluetooth service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Bluetooth service: $e');
      throw Exception('Bluetooth initialization failed: $e');
    }
  }

  /// Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    if (!_isInitialized) await initialize();

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      _logger.e('Failed to get paired devices: $e');
      return [];
    }
  }

  /// Start discovery for nearby devices
  Future<Stream<BluetoothDiscoveryResult>> startDiscovery() async {
    if (!_isInitialized) await initialize();

    try {
      return FlutterBluetoothSerial.instance.startDiscovery();
    } catch (e) {
      _logger.e('Failed to start discovery: $e');
      throw Exception('Failed to start discovery: $e');
    }
  }

  /// Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.i('Connecting to device: ${device.name} (${device.address})');
      
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDeviceId = device.address;
      
      // Set up message listener
      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          _logger.i('Connection closed');
          _handleDisconnection();
        },
        onError: (error) {
          _logger.e('Connection error: $error');
          _handleDisconnection();
        },
      );

      onDeviceConnected?.call(_connectedDeviceId!);
      onConnectionStateChanged?.call(true);
      
      _logger.i('Connected to device: ${device.name}');
    } catch (e) {
      _logger.e('Failed to connect to device: $e');
      throw Exception('Failed to connect to device: $e');
    }
  }

  /// Handle incoming data
  void _onDataReceived(Uint8List data) {
    try {
      final message = String.fromCharCodes(data);
      final messageData = jsonDecode(message);
      
      if (messageData['type'] == 'message') {
        onMessageReceived?.call(messageData['content']);
      }
      
      _logger.d('Received message: ${messageData['content']}');
    } catch (e) {
      _logger.e('Failed to process received data: $e');
    }
  }

  /// Send message
  Future<void> sendMessage(String message) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('No active Bluetooth connection');
    }

    try {
      final messageData = jsonEncode({
        'type': 'message',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': _localDeviceId,
      });

      _connection!.output.add(Uint8List.fromList(messageData.codeUnits));
      await _connection!.output.allSent;
      
      _logger.d('Message sent: $message');
    } catch (e) {
      _logger.e('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send file data
  Future<void> sendFile(Uint8List fileData, String fileName) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('No active Bluetooth connection');
    }

    try {
      // For Bluetooth, we might need to chunk large files
      const chunkSize = 1024; // 1KB chunks for Bluetooth
      final totalChunks = (fileData.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize < fileData.length) ? start + chunkSize : fileData.length;
        final chunk = fileData.sublist(start, end);

        final chunkData = jsonEncode({
          'type': 'file_chunk',
          'fileName': fileName,
          'chunkIndex': i,
          'totalChunks': totalChunks,
          'data': base64Encode(chunk),
          'senderId': _localDeviceId,
        });

        _connection!.output.add(Uint8List.fromList(chunkData.codeUnits));
        await _connection!.output.allSent;
        
        // Small delay between chunks
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _logger.i('File sent: $fileName (${fileData.length} bytes)');
    } catch (e) {
      _logger.e('Failed to send file: $e');
      throw Exception('Failed to send file: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    final deviceId = _connectedDeviceId;
    _connection = null;
    _connectedDeviceId = null;
    
    if (deviceId != null) {
      onDeviceDisconnected?.call(deviceId);
    }
    onConnectionStateChanged?.call(false);
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _handleDisconnection();
        _logger.i('Disconnected from Bluetooth device');
      }
    } catch (e) {
      _logger.e('Error during disconnect: $e');
    }
  }

  /// Check if connected
  bool get isConnected => _connection?.isConnected ?? false;

  /// Get local device info
  Future<BluetoothDevice?> getLocalDevice() async {
    if (!_isInitialized) await initialize();

    try {
      final name = await FlutterBluetoothSerial.instance.name;
      final address = await FlutterBluetoothSerial.instance.address;
      
      if (name != null && address != null) {
        return BluetoothDevice(
          name: name,
          address: address,
          type: BluetoothDeviceType.unknown,
          isConnected: false,
          bondState: BluetoothBondState.none,
        );
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get local device info: $e');
      return null;
    }
  }

  /// Make device discoverable
  Future<void> makeDiscoverable({int duration = 300}) async {
    if (!_isInitialized) await initialize();

    try {
      await FlutterBluetoothSerial.instance.requestDiscoverable(duration);
      _logger.i('Device is now discoverable for $duration seconds');
    } catch (e) {
      _logger.e('Failed to make device discoverable: $e');
      throw Exception('Failed to make device discoverable: $e');
    }
  }

  /// Get connection state
  bool get connectionState => isConnected;

  /// Get connected device ID
  String? get connectedDeviceId => _connectedDeviceId;

  /// Get local device ID
  String? get localDeviceId => _localDeviceId;

  /// Dispose service
  Future<void> dispose() async {
    try {
      await disconnect();
      _isInitialized = false;
      _localDeviceId = null;
      
      // Clear callbacks
      onMessageReceived = null;
      onDeviceConnected = null;
      onDeviceDisconnected = null;
      onConnectionStateChanged = null;
      
      _logger.i('Bluetooth service disposed');
    } catch (e) {
      _logger.e('Error disposing Bluetooth service: $e');
    }
  }
}
