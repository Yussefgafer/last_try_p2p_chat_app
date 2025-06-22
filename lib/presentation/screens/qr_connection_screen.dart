import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../data/services/qr_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/webrtc_service.dart';
import 'p2p_chat_screen.dart';

/// QR Code connection screen for P2P pairing
class QRConnectionScreen extends StatefulWidget {
  const QRConnectionScreen({super.key});

  @override
  State<QRConnectionScreen> createState() => _QRConnectionScreenState();
}

class _QRConnectionScreenState extends State<QRConnectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final QRService _qrService = QRService();
  final UserService _userService = UserService();
  final WebRTCService _webrtcService = WebRTCService();

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;

  String? _myQRData;
  bool _isGeneratingQR = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateMyQR();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrController?.dispose();
    super.dispose();
  }

  Future<void> _generateMyQR() async {
    setState(() {
      _isGeneratingQR = true;
    });

    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final qrData = _qrService.generateConnectionQR(
          peerId: _webrtcService.localPeerId ?? currentUser.deviceId,
          userName: currentUser.name,
          profileImage: currentUser.profileImagePath,
        );

        setState(() {
          _myQRData = qrData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR: $e')),
        );
      }
    } finally {
      setState(() {
        _isGeneratingQR = false;
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isConnecting) {
        _handleScannedQR(scanData.code!);
      }
    });
  }

  Future<void> _handleScannedQR(String qrData) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Pause scanning
      await _qrController?.pauseCamera();

      // Parse QR data
      final connectionInfo = _qrService.parseConnectionQR(qrData);
      if (connectionInfo == null) {
        throw Exception('Invalid QR code format');
      }

      // Show connection dialog
      final shouldConnect = await _showConnectionDialog(connectionInfo);
      if (shouldConnect == true) {
        await _connectToPeer(connectionInfo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
      // Resume scanning
      await _qrController?.resumeCamera();
    }
  }

  Future<bool?> _showConnectionDialog(Map<String, dynamic> connectionInfo) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Peer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${connectionInfo['userName']}'),
            Text('Peer ID: ${connectionInfo['peerId']}'),
            if (connectionInfo['timestamp'] != null)
              Text('Generated: ${DateTime.parse(connectionInfo['timestamp']).toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToPeer(Map<String, dynamic> connectionInfo) async {
    try {
      // Initialize WebRTC service
      await _webrtcService.initialize();

      // Set up callbacks
      _webrtcService.onPeerConnected = (peerId) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => P2PChatScreen(
                peerName: connectionInfo['userName'],
                peerId: peerId,
              ),
            ),
          );
        }
      };

      _webrtcService.onConnectionStateChanged = (state) {
        // Handle connection state changes
      };

      // Start connection process
      // This is a simplified version - in a real app, you'd need signaling
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting to peer...')),
      );
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  void _copyQRToClipboard() {
    if (_myQRData != null) {
      Clipboard.setData(ClipboardData(text: _myQRData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR data copied to clipboard')),
      );
    }
  }

  void _shareQR() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality - Coming Soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect via QR'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'My QR'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My QR Tab
          _buildMyQRTab(theme),
          // Scan QR Tab
          _buildScanQRTab(theme),
        ],
      ),
    );
  }

  Widget _buildMyQRTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header
          Text(
            'Share this QR code to connect',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Others can scan this code to start a P2P chat with you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isGeneratingQR
                ? const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _myQRData != null
                    ? _qrService.generateQRWidget(
                        qrData: _myQRData!,
                        size: 200,
                      )
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: Text('Failed to generate QR'),
                        ),
                      ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _myQRData != null ? _copyQRToClipboard : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _myQRData != null ? _shareQR : null,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _generateMyQR,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate QR'),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This QR code contains your connection information. Keep it private and only share with trusted contacts.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQRTab(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: theme.colorScheme.primary,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
              if (_isConnecting)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Connecting...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Scan a P2P Chat QR code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a QR code to connect',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
