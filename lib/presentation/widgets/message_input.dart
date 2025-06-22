import 'package:flutter/material.dart';
import 'dart:async';

/// Widget for message input with attachments and voice recording
class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final VoidCallback? onSendImage;
  final VoidCallback? onSendFile;
  final VoidCallback? onSendLocation;
  final Function(bool)? onTypingChanged;
  final String? hintText;
  final bool enabled;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.onSendImage,
    this.onSendFile,
    this.onSendLocation,
    this.onTypingChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isRecording = false;
  bool _showAttachments = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    
    if (hasText && !_isTyping) {
      _isTyping = true;
      widget.onTypingChanged?.call(true);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged?.call(false);
      }
    });
  }

  void _sendMessage() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      widget.controller.clear();
      
      // Stop typing indicator
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged?.call(false);
      }
    }
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: Implement voice recording
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Stop voice recording and send
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Attachments panel
          if (_showAttachments) _buildAttachmentsPanel(context),
          
          // Main input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: widget.enabled ? _toggleAttachments : null,
                  icon: Icon(
                    _showAttachments ? Icons.close : Icons.attach_file,
                    color: _showAttachments 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.outline,
                  ),
                ),
                
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      enabled: widget.enabled,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'Type a message...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSubmitted: widget.enabled ? (_) => _sendMessage() : null,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send/Voice button
                GestureDetector(
                  onTap: widget.enabled 
                      ? (hasText ? _sendMessage : null)
                      : null,
                  onLongPressStart: widget.enabled && !hasText 
                      ? (_) => _startVoiceRecording() 
                      : null,
                  onLongPressEnd: widget.enabled && !hasText 
                      ? (_) => _stopVoiceRecording() 
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasText || _isRecording
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop
                          : hasText
                              ? Icons.send
                              : Icons.mic,
                      color: hasText || _isRecording
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.outline,
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

  Widget _buildAttachmentsPanel(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentButton(
            context,
            icon: Icons.photo_camera,
            label: 'Camera',
            color: Colors.green,
            onTap: () {
              _toggleAttachments();
              // TODO: Open camera
            },
          ),
          _buildAttachmentButton(
            context,
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.blue,
            onTap: () {
              _toggleAttachments();
              widget.onSendImage?.call();
            },
          ),
          _buildAttachmentButton(
            context,
            icon: Icons.insert_drive_file,
            label: 'File',
            color: Colors.orange,
            onTap: () {
              _toggleAttachments();
              widget.onSendFile?.call();
            },
          ),
          _buildAttachmentButton(
            context,
            icon: Icons.location_on,
            label: 'Location',
            color: Colors.red,
            onTap: () {
              _toggleAttachments();
              widget.onSendLocation?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}
