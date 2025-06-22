import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/uuid_helper.dart';

/// WebRTC service for P2P communication
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final Logger _logger = Logger();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  // Callbacks
  Function(String message)? onMessageReceived;
  Function(RTCPeerConnectionState state)? onConnectionStateChanged;
  Function(String peerId)? onPeerConnected;
  Function(String peerId)? onPeerDisconnected;
  Function(bool isTyping)? onTypingIndicator;

  bool _isInitialized = false;
  String? _localPeerId;
  String? _remotePeerId;

  /// Initialize WebRTC service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _localPeerId = UuidHelper.generateV4();
      _logger.i('WebRTC Service initialized with peer ID: $_localPeerId');
      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize WebRTC service: $e');
      throw Exception('WebRTC initialization failed: $e');
    }
  }

  /// Create peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    final configuration = AppConstants.rtcConfiguration;

    final peerConnection = await createPeerConnection(configuration);

    // Set up connection state listener
    peerConnection.onConnectionState = (state) {
      _logger.i('Connection state changed: $state');
      onConnectionStateChanged?.call(state);

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onPeerConnected?.call(_remotePeerId ?? 'unknown');
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onPeerDisconnected?.call(_remotePeerId ?? 'unknown');
      }
    };

    // Set up ICE candidate listener
    peerConnection.onIceCandidate = (candidate) {
      _logger.d('ICE candidate generated: ${candidate.candidate}');
      // In a real P2P app, you would send this candidate to the remote peer
      // For now, we'll handle this in the connection establishment process
    };

    return peerConnection;
  }

  /// Create data channel for messaging
  Future<RTCDataChannel> _createDataChannel(
    RTCPeerConnection peerConnection,
  ) async {
    final dataChannelInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 3;

    final dataChannel = await peerConnection.createDataChannel(
      'messages',
      dataChannelInit,
    );

    // Set up message listener
    dataChannel.onMessage = (RTCDataChannelMessage message) {
      try {
        final data = String.fromCharCodes(message.binary);
        final messageData = jsonDecode(data);

        if (messageData['type'] == 'message') {
          onMessageReceived?.call(messageData['content']);
        } else if (messageData['type'] == 'typing') {
          onTypingIndicator?.call(messageData['isTyping']);
        }
      } catch (e) {
        _logger.e('Failed to process received message: $e');
      }
    };

    dataChannel.onDataChannelState = (state) {
      _logger.i('Data channel state: $state');
    };

    return dataChannel;
  }

  /// Start as caller (initiator)
  Future<String> startCall() async {
    if (!_isInitialized) await initialize();

    try {
      _peerConnection = await _createPeerConnection();
      _dataChannel = await _createDataChannel(_peerConnection!);

      // Create offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Return offer SDP for sharing (QR code, etc.)
      return jsonEncode({
        'type': 'offer',
        'sdp': offer.sdp,
        'peerId': _localPeerId,
      });
    } catch (e) {
      _logger.e('Failed to start call: $e');
      throw Exception('Failed to start call: $e');
    }
  }

  /// Answer incoming call
  Future<String> answerCall(String offerData) async {
    if (!_isInitialized) await initialize();

    try {
      final offer = jsonDecode(offerData);
      _remotePeerId = offer['peerId'];

      _peerConnection = await _createPeerConnection();

      // Set up data channel listener for incoming connections
      _peerConnection!.onDataChannel = (dataChannel) {
        _dataChannel = dataChannel;

        dataChannel.onMessage = (RTCDataChannelMessage message) {
          try {
            final data = String.fromCharCodes(message.binary);
            final messageData = jsonDecode(data);

            if (messageData['type'] == 'message') {
              onMessageReceived?.call(messageData['content']);
            } else if (messageData['type'] == 'typing') {
              onTypingIndicator?.call(messageData['isTyping']);
            }
          } catch (e) {
            _logger.e('Failed to process received message: $e');
          }
        };
      };

      // Set remote description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Return answer SDP
      return jsonEncode({
        'type': 'answer',
        'sdp': answer.sdp,
        'peerId': _localPeerId,
      });
    } catch (e) {
      _logger.e('Failed to answer call: $e');
      throw Exception('Failed to answer call: $e');
    }
  }

  /// Complete connection with answer
  Future<void> completeConnection(String answerData) async {
    try {
      final answer = jsonDecode(answerData);
      _remotePeerId = answer['peerId'];

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answer['sdp'], answer['type']),
      );

      _logger.i('Connection completed with peer: $_remotePeerId');
    } catch (e) {
      _logger.e('Failed to complete connection: $e');
      throw Exception('Failed to complete connection: $e');
    }
  }

  /// Send text message
  Future<void> sendMessage(String message) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw Exception('Data channel not available');
    }

    try {
      final messageData = jsonEncode({
        'type': 'message',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': _localPeerId,
      });

      final data = Uint8List.fromList(messageData.codeUnits);
      await _dataChannel!.send(RTCDataChannelMessage.fromBinary(data));

      _logger.d('Message sent: $message');
    } catch (e) {
      _logger.e('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(bool isTyping) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      return; // Silently fail for typing indicators
    }

    try {
      final typingData = jsonEncode({
        'type': 'typing',
        'isTyping': isTyping,
        'senderId': _localPeerId,
      });

      final data = Uint8List.fromList(typingData.codeUnits);
      await _dataChannel!.send(RTCDataChannelMessage.fromBinary(data));
    } catch (e) {
      _logger.w('Failed to send typing indicator: $e');
    }
  }

  /// Send file data
  Future<void> sendFile(
    Uint8List fileData,
    String fileName,
    String mimeType,
  ) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw Exception('Data channel not available');
    }

    try {
      // For large files, we might need to chunk the data
      const chunkSize = 16384; // 16KB chunks
      final totalChunks = (fileData.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize < fileData.length)
            ? start + chunkSize
            : fileData.length;
        final chunk = fileData.sublist(start, end);

        final chunkData = jsonEncode({
          'type': 'file_chunk',
          'fileName': fileName,
          'mimeType': mimeType,
          'chunkIndex': i,
          'totalChunks': totalChunks,
          'data': base64Encode(chunk),
          'senderId': _localPeerId,
        });

        final data = Uint8List.fromList(chunkData.codeUnits);
        await _dataChannel!.send(RTCDataChannelMessage.fromBinary(data));

        // Small delay between chunks to avoid overwhelming the channel
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _logger.i('File sent: $fileName (${fileData.length} bytes)');
    } catch (e) {
      _logger.e('Failed to send file: $e');
      throw Exception('Failed to send file: $e');
    }
  }

  /// Get connection state
  RTCPeerConnectionState? get connectionState =>
      _peerConnection?.connectionState;

  /// Check if connected
  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// Get local peer ID
  String? get localPeerId => _localPeerId;

  /// Get remote peer ID
  String? get remotePeerId => _remotePeerId;

  /// Disconnect from peer
  Future<void> disconnect() async {
    try {
      await _dataChannel?.close();
      await _peerConnection?.close();

      _dataChannel = null;
      _peerConnection = null;
      _remotePeerId = null;

      _logger.i('Disconnected from peer');
    } catch (e) {
      _logger.e('Error during disconnect: $e');
    }
  }

  /// Dispose service
  Future<void> dispose() async {
    await disconnect();
    _isInitialized = false;
    _localPeerId = null;

    // Clear callbacks
    onMessageReceived = null;
    onConnectionStateChanged = null;
    onPeerConnected = null;
    onPeerDisconnected = null;
    onTypingIndicator = null;
  }
}
