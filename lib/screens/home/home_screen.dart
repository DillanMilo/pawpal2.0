import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../utils/theme.dart';
import '../../utils/placeholder_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(PlaceholderData.sampleReminders);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();

    await petProvider.loadPets();
    await activityProvider.loadStats();

    if (petProvider.selectedPet != null) {
      await activityProvider.loadActivities(petProvider.selectedPet!.id, limit: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final userName = authProvider.userProfile?.name?.split(' ').first ?? 'Friend';
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlob(AppTheme.primaryColor.withOpacity(0.05), 300),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildBlob(AppTheme.secondaryColor.withOpacity(0.05), 400),
          ),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(greeting, userName, now)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),

                        // Pet Carousel Section
                        _buildPetSection(petProvider, activityProvider)
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideX(begin: 0.1, end: 0),

                        const SizedBox(height: 32),

                        // Stats Cards
                        _buildStatsSection(activityProvider)
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .scale(begin: const Offset(0.9, 0.9)),

                        const SizedBox(height: 32),

                        // Quick Actions
                        _buildQuickActionsSection(petProvider, activityProvider)
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 32),

                        // Upcoming Reminders
                        _buildRemindersSection()
                            .animate()
                            .fadeIn(delay: 800.ms),

                        const SizedBox(height: 32),

                        // Daily Tip
                        _buildDailyTipCard()
                            .animate()
                            .fadeIn(delay: 1000.ms)
                            .shimmer(delay: 2000.ms, duration: 1500.ms),

                        const SizedBox(height: 140),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: activityProvider.hasActiveTimer
            ? _buildActiveTimerFAB(activityProvider)
            : _buildMainFAB(),
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: 5.seconds, curve: Curves.easeInOut);
  }


  Widget _buildHeader(String greeting, String userName, DateTime now) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return GestureDetector(
      onTap: () => context.push('/reminders'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.textPrimary,
              size: 30,
            ),
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .shake(hz: 2, delay: 5.seconds);
  }

  Widget _buildPetSection(PetProvider petProvider, ActivityProvider activityProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Pets', onSeeAll: () => context.push('/pets')),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: petProvider.pets.isEmpty
              ? _buildSamplePetsCarousel(petProvider, activityProvider)
              : _buildPetsCarousel(petProvider, activityProvider),
        ),
      ],
    );
  }

  Widget _buildSamplePetsCarousel(PetProvider petProvider, ActivityProvider activityProvider) {
    // Show sample pets when no real pets exist
    final samplePets = PlaceholderData.samplePets;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: samplePets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddPetCard();
        }
        final pet = samplePets[index - 1];
        return _buildSamplePetCard(pet, index - 1);
      },
    );
  }

  Widget _buildPetsCarousel(PetProvider petProvider, ActivityProvider activityProvider) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: petProvider.pets.length + 1,
      itemBuilder: (context, index) {
        if (index == petProvider.pets.length) {
          return _buildAddPetCard();
        }
        final pet = petProvider.pets[index];
        final isSelected = petProvider.selectedPet?.id == pet.id;
        return _buildPetCard(pet, isSelected, () {
          petProvider.selectPet(pet);
          activityProvider.loadActivities(pet.id, limit: 10);
        });
      },
    );
  }

  Widget _buildSamplePetCard(Map<String, dynamic> pet, int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentLavender,
      AppTheme.accentColor,
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => context.push('/add-pet'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        pet['emoji'] ?? '🐾',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    pet['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet['breed'] ?? pet['species'],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sample',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPetCard(dynamic pet, bool isSelected, VoidCallback onTap) {
    final color = AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutBack,
        width: 160,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isSelected ? AppTheme.coloredShadow(color) : AppTheme.softShadow,
          border: isSelected 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
            : AppTheme.thickBorder,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: isSelected ? Colors.white : color,
                        size: 32,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.species,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
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

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () => context.push('/add-pet'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: AppTheme.thickBorder,
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ActivityProvider activityProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.accentRose,
            value: '${activityProvider.currentStreak > 0 ? activityProvider.currentStreak : 7}',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            icon: Icons.auto_awesome_rounded,
            color: AppTheme.accentColor,
            value: '${activityProvider.totalPoints > 0 ? activityProvider.totalPoints : 2450}',
            label: 'Paw Points',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: AppTheme.thickBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(PetProvider petProvider, ActivityProvider activityProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 20),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildActionItem('🚶', 'Walk', AppTheme.secondaryColor, () {
                if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Walk', petProvider.selectedPet!.id);
                }
              }),
              _buildActionItem('🎾', 'Play', AppTheme.accentColor, () {
                if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Play', petProvider.selectedPet!.id);
                }
              }),
              _buildActionItem('🍖', 'Feed', AppTheme.accentMint, () {}),
              _buildActionItem('✂️', 'Groom', AppTheme.accentPeach, () {}),
              _buildActionItem('🏥', 'Vet', AppTheme.primaryColor, () {}),
              _buildActionItem('📝', 'Log', AppTheme.accentLavender, () => context.push('/log-activity')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String emoji, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.2), width: 2),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String emoji, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    final activeReminders = _reminders.where((r) => r['completed'] != true).take(2).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upcoming', onSeeAll: () => context.push('/reminders')),
        const SizedBox(height: 16),
        if (activeReminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: AppTheme.thickBorder,
            ),
            child: const Center(
              child: Text(
                'All caught up! 🎉',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...activeReminders.map((reminder) => _buildReminderCard(reminder)),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final color = Color(reminder['color'] as int);
    final isCompleted = reminder['completed'] == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          reminder['completed'] = !isCompleted;
        });
        if (!isCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Completed: ${reminder['title']}! 🐾'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.softShadow,
          border: AppTheme.thickBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Text(reminder['icon'], style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder['title'],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder['time'],
                    style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.successColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.successColor : AppTheme.textLight.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTipCard() {
    final tip = PlaceholderData.petTips[math.Random().nextInt(PlaceholderData.petTips.length)];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.playfulGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip']!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(tip['emoji']!, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildMainFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/log-activity'),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Log Activity', style: TextStyle(fontWeight: FontWeight.w700)),
    ).animate().scale(delay: 1200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActiveTimerFAB(ActivityProvider activityProvider) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/log-activity'),
      backgroundColor: AppTheme.secondaryColor,
      icon: const Icon(Icons.timer_rounded),
      label: Text(
        '${activityProvider.activeActivityType}: ${activityProvider.formattedTimer}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds);
  }
}

class _MapToPet {
  final Map<String, dynamic> map;
  _MapToPet(this.map);
  String get id => map['id'];
  String get name => map['name'];
  String get species => map['species'];
}
