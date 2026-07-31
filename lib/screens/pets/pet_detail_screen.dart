import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pet.dart';
import '../../models/pet_progression.dart';
import '../../providers/activity_provider.dart';
import '../../providers/pet_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/pet_progression_avatar.dart';
import '../medical/medical_records_screen.dart';
import 'pet_passport_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Pet? _pet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    final petProvider = context.read<PetProvider>();
    final activityProvider = context.read<ActivityProvider>();
    final results = await Future.wait([
      petProvider.getPet(widget.petId),
      activityProvider.loadStats(),
    ]);
    final pet = results.first as Pet?;
    if (!mounted) return;
    setState(() {
      _pet = pet;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pet not found')),
      );
    }

    final categoryColor =
        AppTheme.petCategoryColors[_pet!.species] ?? AppTheme.primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Background Blob
          Positioned(
            top: -100,
            right: -50,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: const Offset(-20, -20),
                      end: const Offset(20, 20),
                      duration: 5.seconds,
                    ),
          ),

          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 340,
                  pinned: true,
                  stretch: true,
                  backgroundColor: categoryColor,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Go back',
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      tooltip: 'Edit pet',
                      onPressed: () => context
                          .push('/edit-pet/${_pet!.id}')
                          .then((_) => _loadPet()),
                    ),
                    _buildPopupMenu(),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: _buildHeader(categoryColor),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _TabBarDelegate(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textLight,
                        indicatorColor: AppTheme.primaryColor,
                        indicatorWeight: 4,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Info'),
                          Tab(text: 'Health'),
                          Tab(text: 'Activity'),
                          Tab(text: 'ID'),
                        ],
                      ),
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: Container(
              color: AppTheme.backgroundColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildMedicalTab(),
                  _buildActivityTab(),
                  _buildPassportTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      tooltip: 'More options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 20),
              SizedBox(width: 12),
              Text('Share Passport'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Delete Pet', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteDialog();
        } else if (value == 'share') {
          _showShareDialog();
        }
      },
    );
  }

  Widget _buildHeader(Color categoryColor) {
    final coverPhotoUrl = _pet!.coverPhotoUrl;
    final points = context.watch<ActivityProvider>().pointsForPet(_pet!.id);
    final progression = PetProgression(points);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
        ),
        image: coverPhotoUrl == null || coverPhotoUrl.isEmpty
            ? null
            : DecorationImage(
                image: CachedNetworkImageProvider(coverPhotoUrl),
                fit: BoxFit.cover,
              ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (coverPhotoUrl != null && coverPhotoUrl.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      categoryColor.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
          // Decorative circles
          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              PetProgressionAvatar(
                pet: _pet!,
                points: points,
                size: 140,
                heroTag: 'pet-photo-${_pet!.id}',
                fallbackColor: categoryColor.withValues(alpha: 0.75),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                _pet!.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _headerChip(_pet!.breed ?? _pet!.species),
                  _headerChip(
                    'Level ${progression.level} • ${progression.title}',
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).scale(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProgressionCard() {
    final activityProvider = context.watch<ActivityProvider>();
    final points = activityProvider.pointsForPet(_pet!.id);
    final momentum = activityProvider.momentumForPet(_pet!.id);
    final progression = PetProgression(points);
    final unlockedBadges = progression.unlockedBadges;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.playfulGradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
        boxShadow: AppTheme.shadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_pet!.name}\'s PawPoints',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    Text(
                      'Level ${progression.level} • ${progression.title}',
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$points',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progression.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progression.isMaxLevel
                ? 'Maximum pet level reached!'
                : '${progression.pointsToNextLevel} PawPoints to the next level',
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.accentPeach,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Care Momentum: ${momentum.label}',
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${momentum.activeDays}/${momentum.windowDays} active days',
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: momentum.progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentPeach),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Badges earned',
            style: TextStyle(
              color: AppTheme.primaryText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in unlockedBadges)
                Chip(
                  avatar: Text(badge.emoji ?? '🐾'),
                  label: Text(badge.name),
                  backgroundColor: Colors.white.withValues(alpha: 0.78),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showRewardPicker,
              icon: const Icon(Icons.checkroom_rounded),
              label: const Text('Choose profile rewards'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Walks, play, meals, training, grooming, and wellness care all help ${_pet!.name} grow.',
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.08, end: 0);
  }

  Future<void> _showRewardPicker() async {
    final points = context.read<ActivityProvider>().pointsForPet(_pet!.id);
    final progression = PetProgression(points);
    var selectedFrame = progression.selectedFrame(_pet!.profileFrameId);
    var selectedAccessory = progression.selectedAccessory(
      _pet!.profileAccessoryId,
    );

    final selection = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style ${_pet!.name}\'s profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep earning PawPoints to unlock more. Cosmetics celebrate care and never affect health tracking.',
                  style: TextStyle(color: AppTheme.secondaryText(context)),
                ),
                const SizedBox(height: 24),
                _rewardSection(
                  context: context,
                  title: 'Profile frames',
                  rewards: PetProgression.frames,
                  progression: progression,
                  selectedId: selectedFrame,
                  onSelected: (id) => setSheetState(() => selectedFrame = id),
                ),
                const SizedBox(height: 24),
                _rewardSection(
                  context: context,
                  title: 'Accessories & emojis',
                  rewards: PetProgression.accessories,
                  progression: progression,
                  selectedId: selectedAccessory,
                  onSelected: (id) =>
                      setSheetState(() => selectedAccessory = id),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, (
                      selectedFrame,
                      selectedAccessory,
                    )),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Equip rewards'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selection == null || !mounted) return;
    final updatedPet = _pet!.copyWith(
      profileFrameId: selection.$1,
      profileAccessoryId: selection.$2,
    );
    final saved = await context.read<PetProvider>().updatePet(updatedPet);
    if (!mounted) return;
    if (saved) {
      setState(() => _pet = updatedPet);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_pet!.name}\'s profile rewards are equipped!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PetProvider>().error ?? 'Could not save rewards',
          ),
        ),
      );
    }
  }

  Widget _rewardSection({
    required BuildContext context,
    required String title,
    required List<PetReward> rewards,
    required PetProgression progression,
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final reward in rewards)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RewardChoice(
              reward: reward,
              unlocked: progression.isUnlocked(reward),
              selected: selectedId == reward.id,
              onTap: () => onSelected(reward.id),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildProgressionCard(),
        const SizedBox(height: 24),
        _buildInfoCard('About ${_pet!.name}', [
          _buildInfoRow('Species', _pet!.species, Icons.category_rounded),
          _buildInfoRow('Gender', _pet!.gender, Icons.transgender_rounded),
          _buildInfoRow('Age', _pet!.ageDisplay, Icons.cake_rounded),
          if (_pet!.dateOfBirth != null)
            _buildInfoRow(
              'Birthday',
              DateFormat('MMMM d, y').format(_pet!.dateOfBirth!),
              Icons.event_rounded,
            ),
        ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        _buildInfoCard('Physical Details', [
          if (_pet!.weight != null)
            _buildInfoRow(
              'Weight',
              '${_pet!.weight} kg',
              Icons.monitor_weight_rounded,
            ),
          if (_pet!.colorMarkings != null)
            _buildInfoRow('Color', _pet!.colorMarkings!, Icons.palette_rounded),
          _buildInfoRow(
            'Spayed/Neutered',
            _pet!.spayedNeutered ? 'Yes' : 'No',
            Icons.check_circle_rounded,
          ),
        ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        _buildInfoCard('Identification', [
          if (_pet!.microchipNumber != null)
            _buildInfoRow(
              'Microchip',
              _pet!.microchipNumber!,
              Icons.qr_code_rounded,
            ),
          if (_pet!.adoptionDate != null)
            _buildInfoRow(
              'Adoption',
              DateFormat('MMMM d, y').format(_pet!.adoptionDate!),
              Icons.favorite_rounded,
            ),
        ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.shadowFor(context),
        border: AppTheme.borderFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText(context),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.primaryText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return _buildEmptyTab(
      Icons.medical_services_rounded,
      'Health Records',
      'Keep track of vaccinations, meds, and vet visits.',
      'View Records',
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalRecordsScreen(petId: _pet!.id),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return _buildEmptyTab(
      Icons.auto_graph_rounded,
      'Activity History',
      'See all the fun things you\'ve done together!',
      'View History',
      () => context.push('/pet/${_pet!.id}/activity-history'),
    );
  }

  Widget _buildPassportTab() {
    return _buildEmptyTab(
      Icons.badge_rounded,
      'Pet Passport',
      'A digital ID for your pet to share with others.',
      'View Passport',
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetPassportScreen(petId: _pet!.id),
        ),
      ),
    );
  }

  Widget _buildEmptyTab(
    IconData icon,
    String title,
    String subtitle,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryColor),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.secondaryText(context),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  void _showDeleteDialog() {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Pet?'),
        content: Text(
          'Are you sure you want to delete ${_pet!.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final petProvider = rootContext.read<PetProvider>();
              final success = await petProvider.deletePet(_pet!.id);
              if (success && rootContext.mounted) rootContext.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sharePet() {
    if (_pet == null) return;
    final pet = _pet!;
    final text = StringBuffer();
    text.writeln('Meet ${pet.name}! \u{1F43E}');
    text.writeln('Species: ${pet.species}');
    if (pet.breed != null) text.writeln('Breed: ${pet.breed}');
    text.writeln('Age: ${pet.ageDisplay}');
    if (pet.weight != null) text.writeln('Weight: ${pet.weight} kg');
    text.writeln('');
    text.writeln('Shared via PawPal');
    Share.share(text.toString(), subject: '${pet.name}\'s Profile');
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Share Pet Passport'),
        content: const Text(
          'Generate a shareable profile with your pet\'s info, vaccinations, and emergency contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sharePet();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

class _RewardChoice extends StatelessWidget {
  const _RewardChoice({
    required this.reward,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final PetReward reward;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFrame = reward.type == PetRewardType.frame;
    return Semantics(
      button: unlocked,
      selected: selected,
      label:
          '${reward.name}, ${unlocked ? 'unlocked' : 'unlocks at level ${reward.requiredLevel}'}',
      child: Material(
        color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppTheme.primaryColor
                    : Theme.of(context).dividerColor,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFrame
                        ? LinearGradient(
                            colors: PetProgressionAvatar.frameColors(reward.id),
                          )
                        : null,
                    color: isFrame ? null : AppTheme.primaryLight,
                  ),
                  child: Text(
                    reward.emoji ?? (isFrame ? '🐾' : ''),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unlocked
                            ? reward.description
                            : 'Unlocks at level ${reward.requiredLevel}',
                        style: TextStyle(
                          color: AppTheme.secondaryText(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  unlocked
                      ? selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded
                      : Icons.lock_outline_rounded,
                  color: unlocked
                      ? AppTheme.primaryColor
                      : AppTheme.mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabBarDelegate(this.child);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  double get maxExtent => 64;
  @override
  double get minExtent => 64;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
