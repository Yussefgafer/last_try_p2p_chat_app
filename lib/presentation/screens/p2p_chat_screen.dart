import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../../data/services/webrtc_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/file_service.dart';
import '../../data/models/message_model.dart';
import '../../core/utils/uuid_helper.dart';
import 'media_picker_screen.dart';

/// P2P Chat screen for direct messaging
class P2PChatScreen extends StatefulWidget {
  final String peerName;
  final String peerId;

  const P2PChatScreen({
    super.key,
    required this.peerName,
    required this.peerId,
  });

  @override
  State<P2PChatScreen> createState() => _P2PChatScreenState();
}

class _P2PChatScreenState extends State<P2PChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final WebRTCService _webrtcService = WebRTCService();
  final UserService _userService = UserService();
  final FileService _fileService = FileService();

  final List<MessageModel> _messages = [];
  bool _isConnected = false;
  bool _isTyping = false;
  bool _peerIsTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _setupWebRTC();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _webrtcService.dispose();
    super.dispose();
  }

  void _setupWebRTC() {
    // Set up WebRTC callbacks
    _webrtcService.onMessageReceived = (message) {
      _addMessage(content: message, isFromMe: false);
    };

    _webrtcService.onConnectionStateChanged = (state) {
      setState(() {
        _isConnected = _webrtcService.isConnected;
      });
    };

    _webrtcService.onTypingIndicator = (isTyping) {
      setState(() {
        _peerIsTyping = isTyping;
      });
    };

    _webrtcService.onPeerDisconnected = (peerId) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Peer disconnected')));
      }
    };

    // Check initial connection state
    setState(() {
      _isConnected = _webrtcService.isConnected;
    });
  }

  void _addMessage({
    required String content,
    required bool isFromMe,
    MessageType type = MessageType.text,
  }) {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final message = MessageModel(
      id: UuidHelper.generateMessageId(),
      senderId: isFromMe ? currentUser.id : widget.peerId,
      receiverId: isFromMe ? widget.peerId : currentUser.id,
      conversationId: UuidHelper.generateConversationId([
        currentUser.id,
        widget.peerId,
      ]),
      content: content,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_isConnected) return;

    try {
      // Send via WebRTC
      await _webrtcService.sendMessage(message);

      // Add to local messages
      _addMessage(content: message, isFromMe: true);

      // Clear input
      _messageController.clear();

      // Stop typing indicator
      _stopTyping();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _onTyping() {
    if (!_isTyping && _isConnected) {
      _isTyping = true;
      _webrtcService.sendTypingIndicator(true);
    }

    // Reset timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _webrtcService.sendTypingIndicator(false);
    }
    _typingTimer?.cancel();
  }

  Future<void> _shareMedia() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not connected to peer')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPickerScreen(
          onFileSelected: (file, type) async {
            try {
              // Read file as bytes
              final fileBytes = await _fileService.readFileAsBytes(file);
              if (fileBytes != null) {
                // Send file via WebRTC
                await _webrtcService.sendFile(
                  fileBytes,
                  _fileService.getFileName(file),
                  _fileService.getMimeType(file),
                );

                // Add to local messages
                _addMessage(
                  content: 'Shared ${_fileService.getFileName(file)}',
                  isFromMe: true,
                  type: _getMessageType(type),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send file: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  MessageType _getMessageType(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.file;
    }
  }

  Widget _buildMessage(MessageModel message) {
    final theme = Theme.of(context);
    final isFromMe = message.senderId == _userService.currentUser?.id;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isFromMe ? const Radius.circular(4) : null,
            bottomLeft: !isFromMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isFromMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color:
                    (isFromMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant)
                        .withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_peerIsTyping) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.peerName} is typing',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName),
            Text(
              _isConnected ? 'Connected' : 'Connecting...',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.orange,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.call : Icons.call_end),
            onPressed: () {
              // TODO: Implement voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call - Coming Soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'disconnect':
                  _webrtcService.disconnect();
                  Navigator.of(context).pop();
                  break;
                case 'info':
                  _showConnectionInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Connection Info'),
              ),
              const PopupMenuItem(
                value: 'disconnect',
                child: Text('Disconnect'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Banner
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.errorContainer,
              child: Text(
                'Connecting to ${widget.peerName}...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start chatting with ${widget.peerName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Messages are encrypted end-to-end',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Typing Indicator
          _buildTypingIndicator(),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isConnected ? _shareMedia : null,
                  icon: const Icon(Icons.attach_file),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isConnected
                          ? 'Type a message...'
                          : 'Waiting for connection...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    enabled: _isConnected,
                    onChanged: (_) => _onTyping(),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      _isConnected && _messageController.text.trim().isNotEmpty
                      ? _sendMessage
                      : null,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peer: ${widget.peerName}'),
            Text('Peer ID: ${widget.peerId}'),
            Text('Local ID: ${_webrtcService.localPeerId ?? 'Unknown'}'),
            Text('Status: ${_isConnected ? 'Connected' : 'Disconnected'}'),
            Text('Connection: WebRTC P2P'),
            Text('Encryption: End-to-End'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
