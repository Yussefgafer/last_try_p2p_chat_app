import 'package:flutter/material.dart';

/// Widget that shows typing indicator animation
class TypingIndicator extends StatefulWidget {
  final String? userName;
  final Color? bubbleColor;
  final Color? dotColor;

  const TypingIndicator({
    super.key,
    this.userName,
    this.bubbleColor,
    this.dotColor,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              widget.userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: widget.bubbleColor ?? theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate delay for each dot
        final delay = index * 0.2;
        final progress = (_animation.value + delay) % 1.0;
        
        // Create bounce effect
        final scale = progress < 0.5 
            ? 1.0 + (progress * 0.5)
            : 1.5 - ((progress - 0.5) * 0.5);
        
        final opacity = progress < 0.5 
            ? 0.4 + (progress * 0.6)
            : 1.0 - ((progress - 0.5) * 0.6);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: (widget.dotColor ?? theme.colorScheme.onSurfaceVariant)
                  .withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Simple typing indicator without animation for performance
class SimpleTypingIndicator extends StatelessWidget {
  final String? userName;
  final Color? bubbleColor;
  final Color? textColor;

  const SimpleTypingIndicator({
    super.key,
    this.userName,
    this.bubbleColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: bubbleColor ?? theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'typing...',
              style: TextStyle(
                color: textColor ?? theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Typing indicator for group chats with multiple users
class GroupTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final Color? bubbleColor;
  final Color? textColor;

  const GroupTypingIndicator({
    super.key,
    required this.typingUsers,
    this.bubbleColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    String typingText;
    if (typingUsers.length == 1) {
      typingText = '${typingUsers.first} is typing...';
    } else if (typingUsers.length == 2) {
      typingText = '${typingUsers.first} and ${typingUsers.last} are typing...';
    } else {
      typingText = '${typingUsers.first} and ${typingUsers.length - 1} others are typing...';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bubbleColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          typingText,
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
