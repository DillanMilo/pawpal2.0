import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/activity_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/pet_carousel.dart';
import '../../widgets/activity_chart.dart';
import '../../widgets/quick_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();

    await petProvider.loadPets();
    await activityProvider.loadStats();

    if (petProvider.selectedPet != null) {
      await activityProvider.loadActivities(petProvider.selectedPet!.id,
          limit: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final userName = authProvider.userProfile?.name ?? 'Pet Parent';
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Show notifications
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pet Carousel
                    const SectionTitle(title: 'My Pets'),
                    const SizedBox(height: 12),
                    if (petProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (petProvider.pets.isEmpty)
                      _buildNoPetsCard(context)
                    else
                      PetCarousel(
                        pets: petProvider.pets,
                        selectedPet: petProvider.selectedPet,
                        onPetSelected: (pet) {
                          petProvider.selectPet(pet);
                          activityProvider.loadActivities(pet.id, limit: 10);
                        },
                        onAddPet: () => context.push('/add-pet'),
                      ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    QuickActions(
                      onActivitySelected: (type) {
                        if (petProvider.selectedPet != null) {
                          activityProvider.startTimer(
                            type,
                            petProvider.selectedPet!.id,
                          );
                        }
                      },
                      selectedPet: petProvider.selectedPet,
                    ),

                    const SizedBox(height: 24),

                    // Stats Row
                    _buildStatsRow(activityProvider),

                    const SizedBox(height: 24),

                    // Activity Chart
                    const SectionTitle(title: 'This Week\'s Activity'),
                    const SizedBox(height: 12),
                    ActivityChart(weeklySummary: activityProvider.weeklySummary),

                    const SizedBox(height: 24),

                    // Reminders Section
                    const SectionTitle(title: 'Upcoming Reminders'),
                    const SizedBox(height: 12),
                    _buildRemindersPlaceholder(),

                    const SizedBox(height: 100), // Bottom padding for FAB
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: activityProvider.hasActiveTimer
          ? _buildActiveTimerFAB(activityProvider)
          : null,
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildNoPetsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pets yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first pet to get started',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-pet'),
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ActivityProvider activityProvider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: '${activityProvider.currentStreak}',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            iconColor: AppTheme.accentColor,
            value: '${activityProvider.totalPoints}',
            label: 'Total Points',
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersPlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.successColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No upcoming reminders',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimerFAB(ActivityProvider activityProvider) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await activityProvider.stopTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity logged!')),
          );
        }
      },
      backgroundColor: AppTheme.successColor,
      icon: const Icon(Icons.stop),
      label: Text('Stop ${activityProvider.activeActivityType}'),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionTitle({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
