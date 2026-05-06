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
import 'home_header.dart';
import 'daily_tip_card.dart';
import 'stats_overview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> _reminders;
  late ScrollController _scrollController;
  late Map<String, String> _dailyTip;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(PlaceholderData.sampleReminders);
    _scrollController = ScrollController();
    // Select a daily tip once on init - won't change during scrolling
    _dailyTip = PlaceholderData
        .petTips[math.Random().nextInt(PlaceholderData.petTips.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();

    await petProvider.loadPets();
    await activityProvider.loadStats();

    if (petProvider.selectedPet != null) {
      await activityProvider.loadActivities(
        petProvider.selectedPet!.id,
        limit: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final userName =
        authProvider.userProfile?.name?.split(' ').first ?? 'Friend';
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
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
                child: HomeHeader(greeting: greeting, userName: userName)
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
                    StatsOverview(activityProvider: activityProvider)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildQuickActionsSection()
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 32),

                    // Upcoming Reminders
                    _buildRemindersSection().animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 32),

                    // Activity Graph (moved below reminders)
                    _buildActivityGraphSection(activityProvider)
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .scale(begin: const Offset(0.95, 0.95)),

                    const SizedBox(height: 32),

                    // Daily Tip
                    DailyTipCard(tip: _dailyTip)
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: activityProvider.hasActiveTimer
            ? _buildActiveTimerFAB(activityProvider)
            : _buildMainFAB(),
      ),
    );
  }

  Widget _buildPetSection(
    PetProvider petProvider,
    ActivityProvider activityProvider,
  ) {
    final hasPets = petProvider.pets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'My Pets',
          onSeeAll: hasPets ? () => context.push('/pets') : null,
        ),
        const SizedBox(height: 16),
        if (hasPets)
          SizedBox(
            height: 130,
            child: _buildPetsCarousel(petProvider, activityProvider),
          )
        else
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
          borderRadius: BorderRadius.circular(24),
          border: AppTheme.thickBorder,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.softLavender,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppTheme.primaryDark,
                size: 36,
              ),
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
                color: AppTheme.inkColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsCarousel(
    PetProvider petProvider,
    ActivityProvider activityProvider,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: petProvider.pets.length,
      itemBuilder: (context, index) {
        final pet = petProvider.pets[index];
        final isSelected = petProvider.selectedPet?.id == pet.id;
        return _buildPetCard(pet, isSelected, () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            petProvider.selectPet(pet);
            activityProvider.loadActivities(pet.id, limit: 10);
          });
        });
      },
    );
  }

  Widget _buildPetCard(dynamic pet, bool isSelected, VoidCallback onTap) {
    final color =
        AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 64;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutBack,
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected ? AppTheme.mediumShadow : AppTheme.softShadow,
          border: isSelected
              ? Border.all(color: AppTheme.inkColor, width: 1.5)
              : AppTheme.thickBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                image: pet.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(pet.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.photoUrl == null
                  ? Center(
                      child: Icon(Icons.pets_rounded, color: color, size: 32),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.softLavender
                              : color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          pet.species,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryDark : color,
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
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
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
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.inkColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildActionItem(
                'Walk',
                AppTheme.secondaryColor,
                () => context.push('/log-activity', extra: 'Walk'),
              ),
              _buildActionItem(
                'Play',
                AppTheme.accentColor,
                () => context.push('/log-activity', extra: 'Play'),
              ),
              _buildActionItem(
                'Feed',
                AppTheme.accentMint,
                () => context.push('/log-activity', extra: 'Feed'),
              ),
              _buildActionItem(
                'Groom',
                AppTheme.accentPeach,
                () => context.push('/add-grooming'),
              ),
              _buildActionItem(
                'Vet',
                AppTheme.primaryColor,
                () => context.push('/add-vet-visit'),
              ),
              _buildActionItem(
                'Log',
                AppTheme.accentLavender,
                () => context.push('/log-activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Semantics(
      button: true,
      link: true,
      label: '$label shortcut',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 82,
          margin: const EdgeInsets.only(right: 14),
          child: Column(
            children: [
              ActivityIcon(type: label, isActive: isActive, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityGraphSection(ActivityProvider activityProvider) {
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
        _buildSectionHeader(
          'Weekly Activity',
          onSeeAll: () => context.push('/activity-history'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
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
                          maxY: (maxValue == 0 ? 100 : maxValue * 1.2)
                              .toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
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
                            horizontalInterval: maxValue > 0
                                ? maxValue / 4
                                : 25,
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
                              bottom: BorderSide(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
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
                                      ? const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppTheme.inkColor,
                                            AppTheme.primaryDark,
                                          ],
                                        )
                                      : LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppTheme.primaryLight.withValues(
                                              alpha: 0.4,
                                            ),
                                            AppTheme.primaryLight.withValues(
                                              alpha: 0.7,
                                            ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppTheme.primaryColor, 'Today'),
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    AppTheme.primaryLight.withValues(alpha: 0.6),
                    'This Week',
                  ),
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Map<String, int> _generateSampleWeeklyData() {
    final now = DateTime.now();
    final data = <String, int>{};
    final random = math.Random();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      data[dateStr] = random.nextInt(80) + 20;
    }

    return data;
  }

  Widget _buildRemindersSection() {
    final activeReminders = _reminders
        .where((r) => r['completed'] != true)
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Upcoming',
          onSeeAll: () => context.push('/reminders'),
        ),
        const SizedBox(height: 16),
        if (activeReminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: AppTheme.thickBorder,
            ),
            child: const Center(
              child: Text(
                'All caught up!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
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
              content: Text('Completed: ${reminder['title']}!'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
          border: AppTheme.thickBorder,
        ),
        child: Row(
          children: [
            ActivityIcon(type: reminder['type'], size: 28),
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
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder['time'],
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
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
                  color: isCompleted
                      ? AppTheme.successColor
                      : AppTheme.textLight.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
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
            letterSpacing: 0,
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
      backgroundColor: AppTheme.actionBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Log Activity',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ).animate().scale(delay: 1200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActiveTimerFAB(ActivityProvider activityProvider) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/log-activity'),
      backgroundColor: AppTheme.actionBlueDark,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.timer_rounded),
      label: Text(
        '${activityProvider.activeActivityType}: ${activityProvider.formattedTimer}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds);
  }
}
