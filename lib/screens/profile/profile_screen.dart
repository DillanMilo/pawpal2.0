import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;
  bool _streakNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminderNotifications = prefs.getBool('reminder_notifications') ?? true;
      _streakNotifications = prefs.getBool('streak_notifications') ?? true;
    });
  }

  Future<void> _setNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _onMasterToggle(bool value) {
    setState(() {
      _notificationsEnabled = value;
      if (!value) {
        _reminderNotifications = false;
        _streakNotifications = false;
      }
    });
    _setNotificationPref('notifications_enabled', value);
    if (!value) {
      _setNotificationPref('reminder_notifications', false);
      _setNotificationPref('streak_notifications', false);
      NotificationService().cancelAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final user = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: user?.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user!.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Pet Parent',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.pets,
                  value: '${petProvider.pets.length}',
                  label: 'Pets',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  value: '${activityProvider.currentStreak}',
                  label: 'Day Streak',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  value: '${activityProvider.totalPoints}',
                  label: 'Points',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Menu items
          _MenuSection(
            title: 'Account',
            children: [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () => _showEditProfileDialog(context),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _onMasterToggle,
                ),
                onTap: () {},
              ),
              if (_notificationsEnabled) ...[
                _MenuItem(
                  icon: Icons.alarm_outlined,
                  title: 'Reminder Alerts',
                  trailing: Switch(
                    value: _reminderNotifications,
                    onChanged: (value) {
                      setState(() => _reminderNotifications = value);
                      _setNotificationPref('reminder_notifications', value);
                    },
                  ),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streak Reminders',
                  trailing: Switch(
                    value: _streakNotifications,
                    onChanged: (value) {
                      setState(() => _streakNotifications = value);
                      _setNotificationPref('streak_notifications', value);
                    },
                  ),
                  onTap: () {},
                ),
              ],
              _MenuItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _MenuSection(
            title: 'App',
            children: [
              _MenuItem(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                onTap: () => _showAchievementsDialog(context),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center coming soon!')),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About PawPal',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _MenuSection(
            title: 'Danger Zone',
            children: [
              _MenuItem(
                icon: Icons.logout,
                title: 'Sign Out',
                iconColor: AppTheme.errorColor,
                titleColor: AppTheme.errorColor,
                onTap: () => _showSignOutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'PawPal v1.0.0',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dark mode coming soon!')),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              trailing: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More languages coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Sync Data'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data synced!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed!')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  controller: scrollController,
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _AchievementBadge(
                      icon: Icons.directions_walk,
                      title: 'First Walk',
                      isUnlocked: true,
                    ),
                    _AchievementBadge(
                      icon: Icons.local_fire_department,
                      title: 'Week Warrior',
                      isUnlocked: false,
                    ),
                    _AchievementBadge(
                      icon: Icons.school,
                      title: 'Training Pro',
                      isUnlocked: false,
                    ),
                    _AchievementBadge(
                      icon: Icons.groups,
                      title: 'Social Butterfly',
                      isUnlocked: false,
                    ),
                    _AchievementBadge(
                      icon: Icons.verified,
                      title: 'Health Champion',
                      isUnlocked: false,
                    ),
                    _AchievementBadge(
                      icon: Icons.emoji_events,
                      title: 'Consistent',
                      isUnlocked: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PawPal',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.pets,
          color: AppTheme.primaryColor,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'Your all-in-one pet management companion.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Made with love by Creative Currents LLC',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
              context.read<PetProvider>().reset();
              context.read<ActivityProvider>().reset();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.icon,
    required this.title,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title achievement, ${isUnlocked ? 'unlocked' : 'locked'}',
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : AppTheme.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? AppTheme.accentColor : AppTheme.dividerColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? AppTheme.accentColor : AppTheme.textLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isUnlocked ? AppTheme.textPrimary : AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
