import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer data loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for each section
    _itemAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _slideController,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
    });

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF5),
              Color(0xFFFFE8D6),
              Color(0xFFFFFBF5),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Animated Header
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: _buildHeader(greeting, userName, now),
                  ),
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Pet Carousel Section
                      _buildAnimatedSection(
                        index: 0,
                        child: _buildPetSection(petProvider, activityProvider),
                      ),

                      const SizedBox(height: 28),

                      // Stats Cards
                      _buildAnimatedSection(
                        index: 1,
                        child: _buildStatsSection(activityProvider),
                      ),

                      const SizedBox(height: 28),

                      // Quick Actions
                      _buildAnimatedSection(
                        index: 2,
                        child: _buildQuickActionsSection(petProvider, activityProvider),
                      ),

                      const SizedBox(height: 28),

                      // Upcoming Reminders
                      _buildAnimatedSection(
                        index: 3,
                        child: _buildRemindersSection(),
                      ),

                      const SizedBox(height: 28),

                      // Daily Tip
                      _buildAnimatedSection(
                        index: 4,
                        child: _buildDailyTipCard(),
                      ),

                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: activityProvider.hasActiveTimer
          ? _buildActiveTimerFAB(activityProvider)
          : _buildMainFAB(),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    if (index >= _itemAnimations.length) return child;

    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _itemAnimations[index].value)),
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildHeader(String greeting, String userName, DateTime now) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '7 day streak!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/reminders'),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                : [Colors.white, const Color(0xFFFFFBF5)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected ? AppTheme.coloredShadow(color) : AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 3),
                ),
                child: Center(
                  child: Icon(Icons.pets, color: color, size: 28),
                ),
              ),
              const Spacer(),
              Text(
                pet.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.species,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () => context.push('/add-pet'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Pet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
            iconGradient: AppTheme.sunsetGradient,
            value: '${activityProvider.currentStreak > 0 ? activityProvider.currentStreak : 7}',
            label: 'Day Streak',
            suffix: ' 🔥',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            iconGradient: const LinearGradient(
              colors: [Color(0xFFFFE66D), Color(0xFFFFB347)],
            ),
            value: '${activityProvider.totalPoints > 0 ? activityProvider.totalPoints : 2450}',
            label: 'Points',
            suffix: ' ⭐',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Gradient iconGradient,
    required String value,
    required String label,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (suffix != null)
                      Text(
                        suffix,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip('🚶', 'Walk', AppTheme.secondaryColor, () {
              if (petProvider.selectedPet != null) {
                activityProvider.startTimer('Walk', petProvider.selectedPet!.id);
              }
            }),
            _buildActionChip('🎾', 'Play', AppTheme.accentColor, () {
              if (petProvider.selectedPet != null) {
                activityProvider.startTimer('Play', petProvider.selectedPet!.id);
              }
            }),
            _buildActionChip('🍖', 'Feed', AppTheme.accentMint, () {}),
            _buildActionChip('✂️', 'Groom', AppTheme.accentPeach, () {}),
            _buildActionChip('🏥', 'Vet', AppTheme.primaryColor, () {}),
            _buildActionChip('📝', 'Log', AppTheme.accentLavender, () => context.push('/log-activity')),
          ],
        ),
      ],
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
    final reminders = PlaceholderData.sampleReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upcoming', onSeeAll: () => context.push('/reminders')),
        const SizedBox(height: 16),
        ...reminders.asMap().entries.map((entry) {
          final index = entry.key;
          final reminder = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < reminders.length - 1 ? 12 : 0),
            child: _buildReminderCard(reminder),
          );
        }),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final color = Color(reminder['color'] as int);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                reminder['icon'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder['time'],
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard() {
    final tip = PlaceholderData.petTips[DateTime.now().day % PlaceholderData.petTips.length];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                tip['emoji']!,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['tip']!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildMainFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/log-activity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget _buildActiveTimerFAB(ActivityProvider activityProvider) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await activityProvider.stopTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity logged! 🎉')),
          );
        }
      },
      backgroundColor: AppTheme.successColor,
      icon: const Icon(Icons.stop_rounded),
      label: Text('Stop ${activityProvider.activeActivityType}'),
    );
  }
}
