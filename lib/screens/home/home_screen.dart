import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../utils/theme.dart';
import '../../utils/placeholder_data.dart';
import '../../widgets/activity_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> _reminders;
  late ScrollController _scrollController;
  late Map<String, String> _dailyTip;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(PlaceholderData.sampleReminders);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Select a daily tip once on init - won't change during scrolling
    _dailyTip = PlaceholderData.petTips[math.Random().nextInt(PlaceholderData.petTips.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

    // Calculate background color based on scroll offset
    final scrollProgress = (_scrollOffset / 400).clamp(0.0, 1.0);
    final backgroundColor = Color.lerp(
      AppTheme.backgroundColor,
      const Color(0xFFE8E4F8), // Slightly darker lavender tint
      scrollProgress,
    )!;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              backgroundColor,
            ],
          ),
        ),
        child: Stack(
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
                  controller: _scrollController,
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
                            .fadeIn(delay: 700.ms),

                        const SizedBox(height: 32),

                        // Activity Graph (moved below reminders)
                        _buildActivityGraphSection(activityProvider)
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .scale(begin: const Offset(0.95, 0.95)),

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
    final hasPets = petProvider.pets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Pets', onSeeAll: hasPets ? () => context.push('/pets') : null),
        const SizedBox(height: 16),
        if (hasPets)
          // Show pet cards when pets exist (no add pet card here)
          SizedBox(
            height: 130,
            child: _buildPetsCarousel(petProvider, activityProvider),
          )
        else
          // Show add pet card when no pets
          _buildEmptyPetState(),
      ],
    );
  }

  Widget _buildEmptyPetState() {
    return GestureDetector(
      onTap: () => context.push('/add-pet'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: AppTheme.thickBorder,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.playfulGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Your First Pet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start tracking activities, health & more!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPetsCarousel(PetProvider petProvider, ActivityProvider activityProvider) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: petProvider.pets.length,
      itemBuilder: (context, index) {
        final pet = petProvider.pets[index];
        final isSelected = petProvider.selectedPet?.id == pet.id;
        return _buildPetCard(pet, isSelected, () {
          // Use post frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            petProvider.selectPet(pet);
            activityProvider.loadActivities(pet.id, limit: 10);
          });
        });
      },
    );
  }


  Widget _buildPetCard(dynamic pet, bool isSelected, VoidCallback onTap) {
    final color = AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;
    // Get screen width and calculate card width (leaving some padding on sides)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 64; // 24px padding on each side + 16px for scroll hint

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutBack,
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? AppTheme.coloredShadow(color) : AppTheme.softShadow,
          border: isSelected
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
            : AppTheme.thickBorder,
        ),
        child: Row(
          children: [
            // Pet photo/avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                image: pet.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(pet.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.photoUrl == null
                  ? Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: isSelected ? Colors.white : color,
                        size: 36,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pet.species,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                      if (pet.breed != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pet.breed,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: color, size: 18),
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

  Future<void> _showEndActivityDialog(ActivityProvider activityProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'End Activity?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve been doing ${activityProvider.activeActivityType} for ${activityProvider.formattedTimer}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'No',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await activityProvider.stopTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity logged successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildQuickActionsSection(PetProvider petProvider, ActivityProvider activityProvider) {
    final activeType = activityProvider.activeActivityType;

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
              _buildActionItem('Walk', AppTheme.secondaryColor, () {
                if (activeType == 'Walk') {
                  _showEndActivityDialog(activityProvider);
                } else if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Walk', petProvider.selectedPet!.id);
                }
              }, isActive: activeType == 'Walk'),
              _buildActionItem('Play', AppTheme.accentColor, () {
                if (activeType == 'Play') {
                  _showEndActivityDialog(activityProvider);
                } else if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Play', petProvider.selectedPet!.id);
                }
              }, isActive: activeType == 'Play'),
              _buildActionItem('Feed', AppTheme.accentMint, () {
                if (activeType == 'Feed') {
                  _showEndActivityDialog(activityProvider);
                } else if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Feed', petProvider.selectedPet!.id);
                }
              }, isActive: activeType == 'Feed'),
              _buildActionItem('Groom', AppTheme.accentPeach, () {
                if (activeType == 'Groom') {
                  _showEndActivityDialog(activityProvider);
                } else if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Groom', petProvider.selectedPet!.id);
                }
              }, isActive: activeType == 'Groom'),
              _buildActionItem('Vet', AppTheme.primaryColor, () {
                if (activeType == 'Vet Visit') {
                  _showEndActivityDialog(activityProvider);
                } else if (petProvider.selectedPet != null) {
                  activityProvider.startTimer('Vet Visit', petProvider.selectedPet!.id);
                }
              }, isActive: activeType == 'Vet Visit'),
              _buildActionItem('Log', AppTheme.accentLavender, () => context.push('/log-activity')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String label, Color color, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            ActivityIcon(
              type: label,
              isActive: isActive,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? color : AppTheme.textPrimary,
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

  Widget _buildActivityGraphSection(ActivityProvider activityProvider) {
    // Generate sample data if no real data exists
    final weeklySummary = activityProvider.weeklySummary.isNotEmpty
        ? activityProvider.weeklySummary
        : _generateSampleWeeklyData();

    final sortedKeys = weeklySummary.keys.toList()..sort();
    final maxValue = weeklySummary.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Weekly Activity', onSeeAll: () => context.push('/activity-history')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: AppTheme.thickBorder,
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: weeklySummary.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 48,
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Start logging activities!',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (maxValue == 0 ? 100 : maxValue * 1.2).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toInt()} pts',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= sortedKeys.length) {
                                    return const SizedBox();
                                  }
                                  final dateStr = sortedKeys[value.toInt()];
                                  final date = DateTime.parse(dateStr);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('E').format(date),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxValue > 0 ? maxValue / 4 : 25,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppTheme.dividerColor,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
                              left: BorderSide(color: AppTheme.dividerColor, width: 1),
                            ),
                          ),
                          barGroups: sortedKeys.asMap().entries.map((entry) {
                            final index = entry.key;
                            final dateStr = entry.value;
                            final value = weeklySummary[dateStr] ?? 0;
                            final isToday = _isToday(dateStr);

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value.toDouble(),
                                  gradient: isToday
                                      ? AppTheme.playfulGradient
                                      : LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppTheme.primaryLight.withOpacity(0.4),
                                            AppTheme.primaryLight.withOpacity(0.7),
                                          ],
                                        ),
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppTheme.primaryColor, 'Today'),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppTheme.primaryLight.withOpacity(0.6), 'This Week'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _isToday(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Map<String, int> _generateSampleWeeklyData() {
    final now = DateTime.now();
    final data = <String, int>{};
    final random = math.Random();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      data[dateStr] = random.nextInt(80) + 20; // Random value between 20-100
    }

    return data;
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
            ActivityIcon(
              type: reminder['type'],
              size: 28,
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
                  _dailyTip['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _dailyTip['tip']!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(_dailyTip['emoji']!, style: const TextStyle(fontSize: 48)),
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
