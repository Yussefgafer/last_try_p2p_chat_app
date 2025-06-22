import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import 'profile_screen.dart';
import 'ai_settings_screen.dart';
import 'language_settings_screen.dart';

/// Advanced settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  bool _darkMode = true;
  bool _notifications = true;
  bool _autoConnect = true;
  bool _encryptMessages = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account', Icons.person),
          _buildAccountTile(context),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance', Icons.palette),
          _buildAppearanceSettings(context),
          const SizedBox(height: 24),

          // Connection Section
          _buildSectionHeader(context, 'Connection & Network', Icons.wifi),
          _buildConnectionSettings(context),
          const SizedBox(height: 24),

          // AI Section
          _buildSectionHeader(context, 'Artificial Intelligence', Icons.smart_toy),
          _buildAISettings(context),
          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader(context, 'Privacy & Security', Icons.security),
          _buildPrivacySettings(context),
          const SizedBox(height: 24),

          // Language Section
          _buildSectionHeader(context, 'Language', Icons.language),
          _buildLanguageSettings(context),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(context, 'About', Icons.info),
          _buildAboutSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context) {
    final theme = Theme.of(context);
    final user = _userService.currentUser;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: user?.hasProfileImage == true
              ? ClipOval(
                  child: Image.network(
                    user!.profileImagePath!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimary,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  color: theme.colorScheme.onPrimary,
                ),
        ),
        title: Text(user?.displayName ?? 'Unknown User'),
        subtitle: Text(user?.email ?? 'No email'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // TODO: Implement theme switching
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme Color'),
            subtitle: const Text('Choose app color scheme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show color picker
              _showColorPicker(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto Connect'),
            subtitle: const Text('Automatically connect to known peers'),
            value: _autoConnect,
            onChanged: (value) {
              setState(() {
                _autoConnect = value;
              });
            },
            secondary: const Icon(Icons.wifi),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Bluetooth Settings'),
            subtitle: const Text('Manage Bluetooth connections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to Bluetooth settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Network Diagnostics'),
            subtitle: const Text('Test connection quality'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show network diagnostics
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAISettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI Assistant Settings'),
            subtitle: const Text('Configure Gemini AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AISettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('AI Features'),
            subtitle: const Text('Enable/disable AI features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show AI features settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Encrypt Messages'),
            subtitle: const Text('End-to-end encryption'),
            value: _encryptMessages,
            onChanged: (value) {
              setState(() {
                _encryptMessages = value;
              });
            },
            secondary: const Icon(Icons.lock),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage blocked contacts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to blocked users
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear Data'),
            subtitle: const Text('Delete all messages and data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearDataDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Language'),
        subtitle: const Text('Choose app language'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSettingsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About P2P Chat'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Color'),
        content: const Text('Color picker coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all messages, conversations, and user data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared successfully')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'P2P Chat',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.chat, size: 48),
      children: [
        const Text(
          'A peer-to-peer chat application with AI integration. '
          'Connect directly with others without servers.',
        ),
      ],
    );
  }
}
