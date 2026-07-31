import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/pet.dart';
import '../../models/care_momentum.dart';
import '../../models/pet_progression.dart';
import '../../models/reminder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';
import '../../utils/theme.dart';
import '../../utils/placeholder_data.dart';
import '../../widgets/activity_icon.dart';
import '../../widgets/pet_progression_avatar.dart';
import 'home_backdrop.dart';
import 'home_header.dart';
import 'daily_tip_card.dart';
import 'stats_overview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ReminderService _reminderService = ReminderService();
  List<Reminder> _reminders = [];
  late ScrollController _scrollController;
  late PageController _petPageController;
  Timer? _petCarouselTimer;
  int _petCarouselLength = 0;
  int _petPageIndex = 0;
  late Map<String, String> _dailyTip;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _petPageController = PageController(viewportFraction: 0.94);
    // Select a daily tip once on init - won't change during scrolling
    _dailyTip = PlaceholderData
        .petTips[math.Random().nextInt(PlaceholderData.petTips.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _petCarouselTimer?.cancel();
    _petPageController.dispose();
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
    _syncPetCarouselToSelectedPet(petProvider);

    await _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _reminderService.getActiveReminders();
      if (mounted) setState(() => _reminders = reminders);
    } catch (_) {
      // The home dashboard stays usable without reminders; the reminders
      // screen surfaces its own errors.
    }
  }

  Future<void> _completeReminder(Reminder reminder) async {
    try {
      final result = await _reminderService.markAsCompleted(reminder.id);
      await NotificationService().cancelReminderNotifications(reminder.id);
      if (result.next != null) {
        await NotificationService().scheduleReminderNotification(result.next!);
      }
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed: ${reminder.title}!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
    _configurePetCarouselTimer(petProvider.pets.length);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: HomeBackdrop(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useWideTabletLayout = constraints.maxWidth >= 900;
              final mobileContentWidth = math.min(constraints.maxWidth, 760.0);
              return RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primaryColor,
                child: useWideTabletLayout
                    ? _buildWideTabletDashboard(
                        greeting: greeting,
                        userName: userName,
                        petProvider: petProvider,
                        activityProvider: activityProvider,
                      )
                    : _buildMobileDashboard(
                        greeting: greeting,
                        userName: userName,
                        petProvider: petProvider,
                        activityProvider: activityProvider,
                        contentWidth: mobileContentWidth,
                      ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: activityProvider.hasActiveTimer
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: _buildActiveTimerFAB(activityProvider),
            )
          : null,
    );
  }

  Widget _buildMobileDashboard({
    required String greeting,
    required String userName,
    required PetProvider petProvider,
    required ActivityProvider activityProvider,
    required double contentWidth,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child:
                SizedBox(
                      width: contentWidth,
                      child: HomeHeader(greeting: greeting, userName: userName),
                    )
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .slideY(
                      begin: -0.06,
                      end: 0,
                      duration: 280.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildPetSection(
                      petProvider,
                      activityProvider,
                    ).animate().fadeIn(delay: 60.ms, duration: 240.ms),
                    const SizedBox(height: 24),
                    StatsOverview(
                      activityProvider: activityProvider,
                    ).animate().fadeIn(delay: 100.ms, duration: 240.ms),
                    const SizedBox(height: 28),
                    _buildQuickActionsSection().animate().fadeIn(
                      delay: 140.ms,
                      duration: 240.ms,
                    ),
                    const SizedBox(height: 28),
                    _buildRemindersSection().animate().fadeIn(
                      delay: 180.ms,
                      duration: 240.ms,
                    ),
                    const SizedBox(height: 28),
                    _buildActivityGraphSection(
                      activityProvider,
                    ).animate().fadeIn(delay: 220.ms, duration: 240.ms),
                    const SizedBox(height: 28),
                    DailyTipCard(
                      tip: _dailyTip,
                    ).animate().fadeIn(delay: 260.ms, duration: 240.ms),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTabletDashboard({
    required String greeting,
    required String userName,
    required PetProvider petProvider,
    required ActivityProvider activityProvider,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: HomeHeader(greeting: greeting, userName: userName)
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .slideY(
                    begin: -0.04,
                    end: 0,
                    duration: 260.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPetSection(petProvider, activityProvider),
                          const SizedBox(height: 28),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 28),
                          _buildActivityGraphSection(activityProvider),
                          const SizedBox(height: 28),
                          DailyTipCard(tip: _dailyTip),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatsOverview(activityProvider: activityProvider),
                          const SizedBox(height: 28),
                          _buildRemindersSection(),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 70.ms, duration: 260.ms),
              ),
            ),
          ),
        ),
      ],
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
            height: 162,
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
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: AppTheme.borderFor(context),
          boxShadow: AppTheme.shadowFor(context),
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
                  Text(
                    'Add Your First Pet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start tracking activities, health & more!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText(context),
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
    return PageView.builder(
      controller: _petPageController,
      physics: const BouncingScrollPhysics(),
      padEnds: false,
      itemCount: petProvider.pets.length,
      onPageChanged: (index) {
        _selectPetAtIndex(index, petProvider, activityProvider);
      },
      itemBuilder: (context, index) {
        final pet = petProvider.pets[index];
        final isSelected = petProvider.selectedPet?.id == pet.id;
        final points = activityProvider.pointsForPet(pet.id);
        final momentum = activityProvider.momentumForPet(pet.id);
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildPetCard(pet, points, momentum, isSelected, () {
            _activatePetCard(index, petProvider, activityProvider);
          }),
        );
      },
    );
  }

  Widget _buildPetCard(
    Pet pet,
    int points,
    CareMomentum momentum,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color =
        AppTheme.petCategoryColors[pet.species] ?? AppTheme.primaryColor;
    final isDark = AppTheme.isDark(context);
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final hasCover = pet.coverPhotoUrl != null && pet.coverPhotoUrl!.isNotEmpty;
    final progression = PetProgression(points);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select ${pet.name}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: 180.ms,
          curve: Curves.easeOutCubic,
          scale: isSelected ? 1 : (isTablet ? 0.98 : 0.96),
          child: AnimatedContainer(
            duration: 220.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(18),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isSelected || hasCover
                  ? null
                  : AppTheme.cardBackground(context),
              gradient: hasCover
                  ? null
                  : isSelected
                  ? (isDark
                        ? const LinearGradient(
                            colors: [AppTheme.darkCard, AppTheme.primaryDark],
                          )
                        : AppTheme.homeHeroGradient)
                  : null,
              image: hasCover
                  ? DecorationImage(
                      image: NetworkImage(pet.coverPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              borderRadius: BorderRadius.circular(isTablet ? 24 : 26),
              boxShadow: isSelected && !AppTheme.isDark(context)
                  ? (isTablet ? AppTheme.softShadow : AppTheme.mediumShadow)
                  : AppTheme.shadowFor(context),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.isDark(context)
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor.withValues(alpha: 0.55),
                      width: 1.5,
                    )
                  : AppTheme.borderFor(context),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasCover)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.68),
                          Colors.black.withValues(alpha: 0.34),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    PetProgressionAvatar(
                      pet: pet,
                      points: points,
                      size: 72,
                      fallbackColor: isSelected || hasCover
                          ? Colors.white.withValues(alpha: 0.18)
                          : color.withValues(alpha: 0.46),
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
                              color: isSelected || hasCover
                                  ? Colors.white
                                  : AppTheme.primaryText(context),
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
                                  color: isSelected || hasCover
                                      ? Colors.white.withValues(alpha: 0.14)
                                      : color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  'Level ${progression.level}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected || hasCover
                                        ? Colors.white
                                        : color,
                                  ),
                                ),
                              ),
                              if (pet.breed != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    pet.breed!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected || hasCover
                                          ? Colors.white.withValues(alpha: 0.74)
                                          : AppTheme.secondaryText(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$points PawPoints • ${pet.species}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected || hasCover
                                  ? Colors.white.withValues(alpha: 0.76)
                                  : AppTheme.secondaryText(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Care Momentum: ${momentum.label} • ${momentum.activeDays}/7 days',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected || hasCover
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : AppTheme.secondaryText(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPetAtIndex(
    int index,
    PetProvider petProvider,
    ActivityProvider activityProvider,
  ) {
    if (index < 0 || index >= petProvider.pets.length) return;

    _petPageIndex = index;
    final pet = petProvider.pets[index];
    if (petProvider.selectedPet?.id == pet.id) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      petProvider.selectPet(pet);
      activityProvider.loadActivities(pet.id, limit: 10);
    });
  }

  Future<void> _activatePetCard(
    int index,
    PetProvider petProvider,
    ActivityProvider activityProvider,
  ) async {
    if (index != _petPageIndex && _petPageController.hasClients) {
      await _petPageController.animateToPage(
        index,
        duration: 420.ms,
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _selectPetAtIndex(index, petProvider, activityProvider);
  }

  void _syncPetCarouselToSelectedPet(PetProvider petProvider) {
    final selectedPet = petProvider.selectedPet;
    if (selectedPet == null) return;

    final selectedIndex = petProvider.pets.indexWhere(
      (pet) => pet.id == selectedPet.id,
    );
    if (selectedIndex == -1) return;

    _petPageIndex = selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_petPageController.hasClients) return;
      _petPageController.jumpToPage(selectedIndex);
    });
  }

  void _configurePetCarouselTimer(int petCount) {
    if (_petCarouselLength == petCount &&
        (petCount <= 1 || (_petCarouselTimer?.isActive ?? false))) {
      return;
    }

    _petCarouselLength = petCount;
    _petCarouselTimer?.cancel();
    _petCarouselTimer = null;

    if (petCount <= 1) return;

    _petCarouselTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _advancePetCarousel();
    });
  }

  Future<void> _advancePetCarousel() async {
    if (!mounted || !_petPageController.hasClients) return;

    final petProvider = context.read<PetProvider>();
    if (petProvider.pets.length <= 1) return;

    final nextIndex = (_petPageIndex + 1) % petProvider.pets.length;
    await _petPageController.animateToPage(
      nextIndex,
      duration: 520.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 20) / 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildActionItem(
                  'Walk',
                  AppTheme.secondaryColor,
                  () => context.push('/log-activity', extra: 'Walk'),
                  width: itemWidth,
                ),
                _buildActionItem(
                  'Play',
                  AppTheme.accentColor,
                  () => context.push('/log-activity', extra: 'Play'),
                  width: itemWidth,
                ),
                _buildActionItem(
                  'Feed',
                  AppTheme.accentMint,
                  () => context.push('/log-activity', extra: 'Feed'),
                  width: itemWidth,
                ),
                _buildActionItem(
                  'Groom',
                  AppTheme.accentPeach,
                  () => context.push('/add-grooming'),
                  width: itemWidth,
                ),
                _buildActionItem(
                  'Vet',
                  AppTheme.primaryColor,
                  () => context.push('/add-vet-visit'),
                  width: itemWidth,
                ),
                _buildActionItem(
                  'Log',
                  AppTheme.accentLavender,
                  () => context.push('/log-activity'),
                  width: itemWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
    required double width,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      link: true,
      label: '$label shortcut',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 180.ms,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.14)
                : AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.42)
                  : (isDark ? AppTheme.darkDivider : AppTheme.dividerColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActivityIcon(
                type: label,
                isActive: isActive,
                size: 21,
                showBorder: false,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? color
                      : (isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityGraphSection(ActivityProvider activityProvider) {
    final weeklySummary = activityProvider.weeklySummary;
    final hasActivityData = weeklySummary.values.any((points) => points > 0);

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
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(24),
            border: AppTheme.borderFor(context),
            boxShadow: AppTheme.shadowFor(context),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: !hasActivityData
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
                            Text(
                              'Start logging activities!',
                              style: TextStyle(
                                color: AppTheme.secondaryText(context),
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
                                      style: TextStyle(
                                        color: AppTheme.secondaryText(context),
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
                                    style: TextStyle(
                                      color: AppTheme.mutedText(context),
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
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryText(context),
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

  Widget _buildRemindersSection() {
    final activeReminders = _reminders.take(2).toList();

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
              color: AppTheme.cardBackground(context),
              borderRadius: BorderRadius.circular(24),
              border: AppTheme.borderFor(context),
            ),
            child: Center(
              child: Text(
                'All caught up!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondaryText(context),
                ),
              ),
            ),
          )
        else
          ...activeReminders.map((reminder) => _buildReminderCard(reminder)),
      ],
    );
  }

  String _reminderDueLabel(Reminder reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(
      reminder.dueDate.year,
      reminder.dueDate.month,
      reminder.dueDate.day,
    );

    final time = DateFormat('h:mm a').format(reminder.dueDate);
    if (dueDay.isBefore(today)) {
      final days = today.difference(dueDay).inDays;
      return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
    } else if (dueDay == today) {
      return 'Today at $time';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow at $time';
    }
    return DateFormat('MMM d, h:mm a').format(reminder.dueDate);
  }

  Widget _buildReminderCard(Reminder reminder) {
    final color = reminder.isDue
        ? AppTheme.errorColor
        : reminder.isDueToday
        ? AppTheme.warningColor
        : AppTheme.primaryColor;

    return Semantics(
      button: true,
      label: '${reminder.title} reminder, ${_reminderDueLabel(reminder)}',
      child: GestureDetector(
        onTap: () => context.push('/reminders'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowFor(context),
            border: AppTheme.borderFor(context),
          ),
          child: Row(
            children: [
              ActivityIcon(type: reminder.type, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _reminderDueLabel(reminder),
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _completeReminder(reminder),
                tooltip: 'Mark as complete',
                icon: const Icon(Icons.check_circle_outline),
                color: AppTheme.successColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final actionColor = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: titleColor,
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
                    color: actionColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: actionColor),
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
