import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';
import '../../core/utils/encryption_helper.dart';
import '../../core/utils/uuid_helper.dart';

/// Service for QR code generation and scanning for P2P connections
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final EncryptionHelper _encryption = EncryptionHelper();

  /// Generate QR code data for connection
  String generateConnectionQR({
    required String peerId,
    required String userName,
    String? profileImage,
    Map<String, dynamic>? connectionData,
  }) {
    final connectionInfo = {
      'version': '1.0',
      'type': 'p2p_connection',
      'peerId': peerId,
      'userName': userName,
      'profileImage': profileImage,
      'timestamp': DateTime.now().toIso8601String(),
      'connectionId': UuidHelper.generateV4(),
      'data': connectionData,
    };

    // Convert to JSON and encode
    final jsonData = jsonEncode(connectionInfo);
    return base64Encode(utf8.encode(jsonData));
  }

  /// Parse QR code data
  Map<String, dynamic>? parseConnectionQR(String qrData) {
    try {
      // Decode base64 and parse JSON
      final decodedData = utf8.decode(base64Decode(qrData));
      final connectionInfo = jsonDecode(decodedData) as Map<String, dynamic>;

      // Validate required fields
      if (connectionInfo['type'] != 'p2p_connection' ||
          connectionInfo['peerId'] == null ||
          connectionInfo['userName'] == null) {
        return null;
      }

      return connectionInfo;
    } catch (e) {
      return null;
    }
  }

  /// Generate QR widget for display
  Widget generateQRWidget({
    required String qrData,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(8),
    );
  }

  /// Generate connection invitation QR
  String generateInvitationQR({
    required String peerId,
    required String userName,
    String? profileImage,
    String? invitationMessage,
  }) {
    final invitationData = {
      'version': '1.0',
      'type': 'p2p_invitation',
      'peerId': peerId,
      'userName': userName,
      'profileImage': profileImage,
      'message': invitationMessage ?? 'Join me on P2P Chat!',
      'timestamp': DateTime.now().toIso8601String(),
      'invitationId': UuidHelper.generateV4(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    };

    final jsonData = jsonEncode(invitationData);
    return base64Encode(utf8.encode(jsonData));
  }

  /// Parse invitation QR
  Map<String, dynamic>? parseInvitationQR(String qrData) {
    try {
      final decodedData = utf8.decode(base64Decode(qrData));
      final invitationInfo = jsonDecode(decodedData) as Map<String, dynamic>;

      // Validate required fields
      if (invitationInfo['type'] != 'p2p_invitation' ||
          invitationInfo['peerId'] == null ||
          invitationInfo['userName'] == null) {
        return null;
      }

      // Check if invitation is expired
      if (invitationInfo['expiresAt'] != null) {
        final expiryDate = DateTime.parse(invitationInfo['expiresAt']);
        if (DateTime.now().isAfter(expiryDate)) {
          return null; // Expired invitation
        }
      }

      return invitationInfo;
    } catch (e) {
      return null;
    }
  }

  /// Generate WebRTC offer QR
  String generateOfferQR({
    required String offerSDP,
    required String peerId,
    required String userName,
  }) {
    final offerData = {
      'version': '1.0',
      'type': 'webrtc_offer',
      'offer': offerSDP,
      'peerId': peerId,
      'userName': userName,
      'timestamp': DateTime.now().toIso8601String(),
      'offerId': UuidHelper.generateV4(),
    };

    final jsonData = jsonEncode(offerData);
    return base64Encode(utf8.encode(jsonData));
  }

  /// Parse WebRTC offer QR
  Map<String, dynamic>? parseOfferQR(String qrData) {
    try {
      final decodedData = utf8.decode(base64Decode(qrData));
      final offerInfo = jsonDecode(decodedData) as Map<String, dynamic>;

      // Validate required fields
      if (offerInfo['type'] != 'webrtc_offer' ||
          offerInfo['offer'] == null ||
          offerInfo['peerId'] == null) {
        return null;
      }

      return offerInfo;
    } catch (e) {
      return null;
    }
  }

  /// Validate QR code format
  bool isValidP2PQR(String qrData) {
    final parsed = parseConnectionQR(qrData) ?? 
                  parseInvitationQR(qrData) ?? 
                  parseOfferQR(qrData);
    return parsed != null;
  }

  /// Get QR type
  String? getQRType(String qrData) {
    try {
      final decodedData = utf8.decode(base64Decode(qrData));
      final qrInfo = jsonDecode(decodedData) as Map<String, dynamic>;
      return qrInfo['type'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Generate secure connection QR with encryption
  String generateSecureConnectionQR({
    required String peerId,
    required String userName,
    required String encryptionKey,
    String? profileImage,
    Map<String, dynamic>? connectionData,
  }) {
    final connectionInfo = {
      'version': '1.0',
      'type': 'p2p_secure_connection',
      'peerId': peerId,
      'userName': userName,
      'profileImage': profileImage,
      'timestamp': DateTime.now().toIso8601String(),
      'connectionId': UuidHelper.generateV4(),
      'data': connectionData,
    };

    try {
      // Initialize encryption with the provided key
      _encryption.initialize(encryptionKey);
      
      // Encrypt the connection data
      final jsonData = jsonEncode(connectionInfo);
      final encryptedData = _encryption.encryptText(jsonData);
      
      // Create wrapper with encryption info
      final wrapper = {
        'encrypted': true,
        'data': encryptedData,
        'version': '1.0',
      };

      return base64Encode(utf8.encode(jsonEncode(wrapper)));
    } catch (e) {
      // Fallback to non-encrypted if encryption fails
      return generateConnectionQR(
        peerId: peerId,
        userName: userName,
        profileImage: profileImage,
        connectionData: connectionData,
      );
    }
  }

  /// Parse secure connection QR with decryption
  Map<String, dynamic>? parseSecureConnectionQR(String qrData, String encryptionKey) {
    try {
      final decodedData = utf8.decode(base64Decode(qrData));
      final wrapper = jsonDecode(decodedData) as Map<String, dynamic>;

      if (wrapper['encrypted'] == true) {
        // Initialize encryption with the provided key
        _encryption.initialize(encryptionKey);
        
        // Decrypt the data
        final encryptedData = wrapper['data'] as String;
        final decryptedJson = _encryption.decryptText(encryptedData);
        final connectionInfo = jsonDecode(decryptedJson) as Map<String, dynamic>;

        // Validate decrypted data
        if (connectionInfo['type'] != 'p2p_secure_connection' ||
            connectionInfo['peerId'] == null ||
            connectionInfo['userName'] == null) {
          return null;
        }

        return connectionInfo;
      } else {
        // Try parsing as regular connection QR
        return parseConnectionQR(qrData);
      }
    } catch (e) {
      return null;
    }
  }

  /// Create QR scanner widget
  Widget createQRScanner({
    required Function(String) onQRScanned,
    Function(String)? onError,
  }) {
    return QRScannerWidget(
      onQRScanned: onQRScanned,
      onError: onError,
    );
  }
}

/// QR Scanner Widget
class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRScanned;
  final Function(String)? onError;

  const QRScannerWidget({
    super.key,
    required this.onQRScanned,
    this.onError,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        widget.onQRScanned(scanData.code!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Theme.of(context).colorScheme.primary,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 250,
      ),
    );
  }
}
