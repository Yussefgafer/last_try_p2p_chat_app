import 'package:flutter/material.dart';
import '../../data/models/conversation_model.dart';

/// Widget for displaying conversation in list
class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showUnreadBadge;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.onLongPress,
    this.showUnreadBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildAvatar(context),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: conversation.hasUnreadMessages 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.isPinned)
              Icon(
                Icons.push_pin,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            if (conversation.isMuted)
              Icon(
                Icons.volume_off,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessagePreview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: conversation.hasUnreadMessages
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: conversation.hasUnreadMessages 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusIcon(context),
                const SizedBox(width: 4),
                Text(
                  conversation.formattedLastMessageTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (conversation.isGroup) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.group,
                    size: 12,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${conversation.participantCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showUnreadBadge && conversation.hasUnreadMessages)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount > 99 
                      ? '99+' 
                      : conversation.unreadCount.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    
    if (conversation.hasAvatar) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(conversation.avatarPath!),
        onBackgroundImageError: (_, __) {
          // Fallback to default avatar
        },
      );
    }

    // Default avatar based on conversation type
    IconData iconData;
    Color backgroundColor;
    
    switch (conversation.type) {
      case ConversationType.ai:
        iconData = Icons.smart_toy;
        backgroundColor = theme.colorScheme.primary;
        break;
      case ConversationType.group:
        iconData = Icons.group;
        backgroundColor = theme.colorScheme.secondary;
        break;
      case ConversationType.individual:
      default:
        iconData = Icons.person;
        backgroundColor = theme.colorScheme.tertiary;
        break;
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);
    
    if (conversation.isAI) {
      return Icon(
        Icons.smart_toy,
        size: 12,
        color: theme.colorScheme.primary,
      );
    }
    
    if (conversation.isGroup) {
      return Icon(
        Icons.group,
        size: 12,
        color: theme.colorScheme.secondary,
      );
    }
    
    // For individual chats, show online status
    return Icon(
      Icons.circle,
      size: 8,
      color: theme.colorScheme.primary, // Assume online for now
    );
  }
}

/// Conversation tile with swipe actions
class SwipeableConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onMute;
  final VoidCallback? onPin;

  const SwipeableConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onMute,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: theme.colorScheme.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      secondaryBackground: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete action
          return await _showDeleteConfirmation(context);
        } else {
          // Pin/Unpin action
          onPin?.call();
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      child: ConversationTile(
        conversation: conversation,
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete the conversation with ${conversation.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            ),
            title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
            onTap: () {
              Navigator.pop(context);
              onPin?.call();
            },
          ),
          ListTile(
            leading: Icon(
              conversation.isMuted ? Icons.volume_up : Icons.volume_off,
            ),
            title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
            onTap: () {
              Navigator.pop(context);
              onMute?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archive'),
            onTap: () {
              Navigator.pop(context);
              onArchive?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }
}
