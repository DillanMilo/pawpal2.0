import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/medical_record.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/medical_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MedicalService _medicalService = MedicalService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;
  bool _streakNotifications = true;
  bool _dailyActivityReminder = false;
  Map<MedicalRecordType, int> _medicalRecordCountsByType = {};
  bool _isLoadingAchievementData = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final profileNotifications = context
        .read<AuthProvider>()
        .userProfile
        ?.notificationsEnabled;
    setState(() {
      _notificationsEnabled =
          profileNotifications ??
          prefs.getBool('notifications_enabled') ??
          true;
      _reminderNotifications = prefs.getBool('reminder_notifications') ?? true;
      _streakNotifications = prefs.getBool('streak_notifications') ?? true;
      _dailyActivityReminder =
          prefs.getBool('daily_activity_reminder') ?? false;
    });
  }

  Future<void> _setNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _onMasterToggle(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      if (!value) {
        _reminderNotifications = false;
        _streakNotifications = false;
        _dailyActivityReminder = false;
      }
    });
    await _setNotificationPref('notifications_enabled', value);
    if (mounted) {
      await context.read<AuthProvider>().updateNotificationPreference(value);
    }
    if (!value) {
      await _setNotificationPref('reminder_notifications', false);
      await _setNotificationPref('streak_notifications', false);
      await _setNotificationPref('daily_activity_reminder', false);
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _onReminderToggle(bool value) async {
    setState(() => _reminderNotifications = value);
    await _setNotificationPref('reminder_notifications', value);
  }

  Future<void> _onStreakToggle(bool value) async {
    setState(() => _streakNotifications = value);
    await _setNotificationPref('streak_notifications', value);
    if (value) {
      await NotificationService().scheduleStreakReminder();
    } else {
      // ID 1 is the streak reminder; the daily reminder (ID 0) has its own
      // toggle.
      await NotificationService().cancelNotification(1);
    }
  }

  Future<void> _onDailyReminderToggle(bool value) async {
    setState(() => _dailyActivityReminder = value);
    await _setNotificationPref('daily_activity_reminder', value);
    if (value) {
      await NotificationService().scheduleDailyActivityReminder(
        hour: 9,
        minute: 0,
      );
    } else {
      await NotificationService().cancelNotification(0);
    }
  }

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();

    if (mounted) {
      setState(() => _isLoadingAchievementData = true);
    }

    await petProvider.loadPets(forceRefresh: forceRefresh);
    await activityProvider.loadStats(forceRefresh: forceRefresh);

    try {
      final counts = await _medicalService.getMedicalRecordCountsByType(
        petProvider.pets.map((pet) => pet.id).toList(),
      );
      if (mounted) {
        setState(() => _medicalRecordCountsByType = counts);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _medicalRecordCountsByType = {});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAchievementData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.userProfile;
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
        padding: EdgeInsets.fromLTRB(16, 16, 16, 128 + bottomInset),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showEditProfileDialog(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
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
                        child: ClipOval(child: _ProfileAvatar(profile: user)),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.actionBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cardBackground(context),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Pet Parent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
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
                    onChanged: _onReminderToggle,
                  ),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streak Reminders',
                  trailing: Switch(
                    value: _streakNotifications,
                    onChanged: _onStreakToggle,
                  ),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Daily Reminder (9 AM)',
                  trailing: Switch(
                    value: _dailyActivityReminder,
                    onChanged: _onDailyReminderToggle,
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
                icon: Icons.palette_outlined,
                title: 'Appearance',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themeProvider.label,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showSettingsDialog(context),
              ),
              _MenuItem(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                onTap: () async {
                  await _loadProfileData(forceRefresh: true);
                  if (context.mounted) {
                    _showAchievementsDialog(context);
                  }
                },
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => _contactSupport(context),
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
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                iconColor: AppTheme.errorColor,
                titleColor: AppTheme.errorColor,
                onTap: () => _showDeleteAccountDialog(context),
              ),
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
              style: TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'creativecurrentsx@gmail.com',
      query: 'subject=PawPal Support',
    );
    final launched = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email us at creativecurrentsx@gmail.com'),
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<PawPalThemePreference>(
                      selected: {themeProvider.preference},
                      onSelectionChanged: (selection) {
                        themeProvider.setPreference(selection.first);
                      },
                      segments: const [
                        ButtonSegment(
                          value: PawPalThemePreference.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: PawPalThemePreference.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: PawPalThemePreference.automatic,
                          icon: Icon(Icons.schedule_outlined),
                          label: Text('Auto'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Auto uses light mode during the day and dark mode in the evening.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name ?? '');
    final phoneController = TextEditingController(
      text: profile.phoneNumber ?? '',
    );
    final zipController = TextEditingController(text: profile.zipCode ?? '');
    final formKey = GlobalKey<FormState>();
    XFile? selectedPhoto;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickPhoto() async {
            final picked = await _imagePicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 82,
              maxWidth: 1200,
            );
            if (picked != null) {
              setDialogState(() => selectedPhoto = picked);
            }
          }

          Future<void> saveProfile() async {
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => isSaving = true);
            final success = await authProvider.updateProfileDetails(
              name: nameController.text,
              phoneNumber: phoneController.text,
              zipCode: zipController.text,
              photo: selectedPhoto,
            );

            if (!dialogContext.mounted) return;
            setDialogState(() => isSaving = false);

            if (success) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile saved')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Could not save profile'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EditableProfilePhoto(
                      profile: profile,
                      selectedPhoto: selectedPhoto,
                      onTap: isSaving ? null : pickPhoto,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : saveProfile,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
      zipController.dispose();
    });
  }

  void _showChangePasswordDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> changePassword() async {
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => isSaving = true);
            final success = await authProvider.changePassword(
              currentPassword: currentController.text,
              newPassword: newController.text,
            );

            if (!dialogContext.mounted) return;
            setDialogState(() => isSaving = false);

            if (success) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Password changed')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    authProvider.error ?? 'Could not change password',
                  ),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      if (value == currentController.text) {
                        return 'Use a different password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value != newController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : changePassword,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }

  void _showAchievementsDialog(BuildContext context) {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();
    final achievements = _buildAchievementMilestones(
      petProvider: petProvider,
      activityProvider: activityProvider,
    );
    final unlockedCount = achievements.where((item) => item.isUnlocked).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$unlockedCount/${achievements.length}',
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Milestones update from pets, points, streaks, activities, and saved care records.',
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoadingAchievementData) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: achievements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _AchievementBadge(milestone: achievements[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_AchievementMilestone> _buildAchievementMilestones({
    required PetProvider petProvider,
    required ActivityProvider activityProvider,
  }) {
    final activityCounts = activityProvider.activityCountsByType;
    int activityCount(String type) => activityCounts[type] ?? 0;
    int medicalCount(MedicalRecordType type) =>
        _medicalRecordCountsByType[type] ?? 0;

    final healthRecords =
        medicalCount(MedicalRecordType.vaccination) +
        medicalCount(MedicalRecordType.vetVisit) +
        activityCount('Vet Visit');
    final groomingRecords =
        medicalCount(MedicalRecordType.groomingVisit) + activityCount('Groom');

    return [
      _AchievementMilestone(
        icon: Icons.pets_rounded,
        title: 'Pet Parent',
        description: 'Add your first pet profile.',
        currentValue: petProvider.pets.length,
        threshold: 1,
        color: AppTheme.primaryColor,
      ),
      _AchievementMilestone(
        icon: Icons.directions_walk_rounded,
        title: 'First Walk',
        description: 'Log one walk activity.',
        currentValue: activityCount('Walk'),
        threshold: 1,
        color: AppTheme.secondaryColor,
      ),
      _AchievementMilestone(
        icon: Icons.local_fire_department_rounded,
        title: 'Week Warrior',
        description: 'Keep a 7-day activity streak.',
        currentValue: activityProvider.currentStreak,
        threshold: 7,
        color: Colors.orange,
      ),
      _AchievementMilestone(
        icon: Icons.school_rounded,
        title: 'Training Pro',
        description: 'Complete 10 training sessions.',
        currentValue: activityCount('Train'),
        threshold: 10,
        color: AppTheme.primaryDark,
      ),
      _AchievementMilestone(
        icon: Icons.groups_rounded,
        title: 'Social Butterfly',
        description: 'Log 5 social activities.',
        currentValue: activityCount('Social'),
        threshold: 5,
        color: AppTheme.actionBlue,
      ),
      _AchievementMilestone(
        icon: Icons.verified_rounded,
        title: 'Health Champion',
        description: 'Save a vaccination, vet visit, or vet activity.',
        currentValue: healthRecords,
        threshold: 1,
        color: AppTheme.errorColor,
      ),
      _AchievementMilestone(
        icon: Icons.content_cut_rounded,
        title: 'Freshly Groomed',
        description: 'Save a grooming visit or grooming activity.',
        currentValue: groomingRecords,
        threshold: 1,
        color: AppTheme.accentPeach,
      ),
      _AchievementMilestone(
        icon: Icons.star_rounded,
        title: 'Paw Points',
        description: 'Earn 250 Paw Points.',
        currentValue: activityProvider.totalPoints,
        threshold: 250,
        color: AppTheme.accentColor,
      ),
      _AchievementMilestone(
        icon: Icons.emoji_events_rounded,
        title: 'Consistent Caregiver',
        description: 'Keep a 30-day activity streak.',
        currentValue: activityProvider.currentStreak,
        threshold: 30,
        color: AppTheme.accentLavender,
      ),
    ];
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
        child: const Icon(Icons.pets, color: AppTheme.primaryColor, size: 30),
      ),
      children: [
        const Text('Your all-in-one pet management companion.'),
        const SizedBox(height: 8),
        const Text(
          'Made with love by Creative Currents LLC',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    var isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text(
            'This permanently deletes your PawPal account, pets, reminders, activities, appointments, and medical records. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);

                      final authProvider = context.read<AuthProvider>();
                      final success = await authProvider.deleteAccount();

                      if (!dialogContext.mounted) return;

                      if (success) {
                        context.read<PetProvider>().reset();
                        context.read<ActivityProvider>().reset();
                        Navigator.pop(dialogContext);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your account has been deleted.'),
                            ),
                          );
                        }
                        return;
                      }

                      setDialogState(() => isDeleting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authProvider.error ??
                                  'Failed to delete account. Please try again.',
                            ),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final UserProfile? profile;

  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _AvatarFallback(),
        errorWidget: (context, url, error) => _AvatarFallback(),
      );
    }

    return _AvatarFallback();
  }
}

class _EditableProfilePhoto extends StatelessWidget {
  final UserProfile profile;
  final XFile? selectedPhoto;
  final VoidCallback? onTap;

  const _EditableProfilePhoto({
    required this.profile,
    required this.selectedPhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choose profile photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: selectedPhoto == null
                    ? _ProfileAvatar(profile: profile)
                    : _SelectedProfilePhoto(photo: selectedPhoto!),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.actionBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.cardBackground(context),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedProfilePhoto extends StatelessWidget {
  final XFile photo;

  const _SelectedProfilePhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: photo.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _AvatarFallback();
        }

        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({required this.title, required this.children});

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
        Card(child: Column(children: children)),
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
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _AchievementMilestone {
  final IconData icon;
  final String title;
  final String description;
  final int currentValue;
  final int threshold;
  final Color color;

  const _AchievementMilestone({
    required this.icon,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.threshold,
    required this.color,
  });

  bool get isUnlocked => currentValue >= threshold;

  double get progress =>
      threshold <= 0 ? 0 : (currentValue / threshold).clamp(0.0, 1.0);

  String get progressLabel => isUnlocked
      ? 'Unlocked'
      : '${currentValue.clamp(0, threshold)} / $threshold';
}

class _AchievementBadge extends StatelessWidget {
  final _AchievementMilestone milestone;

  const _AchievementBadge({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final tint = milestone.color.withValues(alpha: isDark ? 0.18 : 0.1);
    final mutedColor = AppTheme.mutedText(context);
    final progressColor = milestone.isUnlocked
        ? milestone.color
        : milestone.color.withValues(alpha: 0.75);

    return Semantics(
      label:
          '${milestone.title} achievement, ${milestone.progressLabel}, ${milestone.description}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: milestone.isUnlocked
                ? milestone.color.withValues(alpha: 0.55)
                : (isDark ? AppTheme.darkDivider : AppTheme.dividerColor),
            width: milestone.isUnlocked ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(
                milestone.isUnlocked ? Icons.check_rounded : milestone.icon,
                color: milestone.isUnlocked ? milestone.color : mutedColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            color: AppTheme.primaryText(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        milestone.progressLabel,
                        style: TextStyle(
                          color: milestone.isUnlocked
                              ? milestone.color
                              : AppTheme.secondaryText(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: milestone.progress,
                      backgroundColor: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
