import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/connectivity.dart';
import 'quick_actions/quick_actions_screen.dart';
import '../widgets/app_tour_overlay.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  final bool replayTour;

  const MainShell({super.key, required this.child, this.replayTour = false});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isOffline = false;
  late final StreamSubscription<bool> _connectivitySub;
  final _homeTourKey = GlobalKey();
  final _servicesTourKey = GlobalKey();
  final _quickActionsTourKey = GlobalKey();
  final _calendarTourKey = GlobalKey();
  final _profileTourKey = GlobalKey();
  bool _tourVisible = false;
  bool _replayStarted = false;
  bool _notificationPermissionRequested = false;
  int _tourStep = 0;

  static const _tourSteps = [
    AppTourStep(
      title: 'Your daily home base',
      description:
          'See today’s care, recent activity, reminders, and a useful daily tip at a glance.',
      icon: Icons.home_rounded,
    ),
    AppTourStep(
      title: 'Trusted services nearby',
      description:
          'Find vets, groomers, trainers, pet stores, and other helpful local care.',
      icon: Icons.store_rounded,
    ),
    AppTourStep(
      title: 'Care that levels them up',
      description:
          'Use the paw button to log walks, meals, play, grooming, training, and wellness care. Each entry earns PawPoints for that pet, raising their level and unlocking badges, profile frames, and cute accessories.',
      icon: Icons.pets_rounded,
    ),
    AppTourStep(
      title: 'Keep every date together',
      description:
          'Events brings appointments, reminders, and care dates into one calm calendar.',
      icon: Icons.calendar_today_rounded,
    ),
    AppTourStep(
      title: 'Profiles for you and your pet',
      description:
          'Manage your pet’s details and health records, adjust PawPal, or replay this tour anytime.',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Check initial state
    ConnectivityHelper.instance.hasInternetConnection().then((online) {
      if (!online && mounted) setState(() => _isOffline = true);
    });
    // Listen for changes
    _connectivitySub = ConnectivityHelper.instance.onConnectivityChanged.listen(
      (online) {
        if (mounted) setState(() => _isOffline = !online);
      },
    );
    // Ask for notification permission once the user is signed in and the
    // shell is visible (Android 13+ requires a runtime request).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTourState();
    });
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replayTour && !oldWidget.replayTour) {
      _replayStarted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncTourState());
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTourState());
    final selectedIndex = _calculateSelectedIndex(context);
    return _buildMobileFirstShell(context, selectedIndex);
  }

  Widget _buildMobileFirstShell(BuildContext context, int selectedIndex) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomInset = bottomPadding > 0 ? bottomPadding : 12.0;
    const navBarHeight = 72.0;
    const pawButtonSize = 66.0;
    const pawButtonOverlap = 29.0;
    const navShellHeight = navBarHeight + pawButtonOverlap;

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: Column(
            children: [
              if (_isOffline) _buildOfflineBanner(context),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: SizedBox(
            height: navShellHeight + bottomInset,
            child: Stack(
              children: [
                Positioned(
                  key: const Key('bottom-navigation-safe-background'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomInset + (navBarHeight / 2),
                  child: ColoredBox(color: AppTheme.surfaceBackground(context)),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: bottomInset,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SizedBox(
                        height: navShellHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: navBarHeight,
                              child: _buildNavBarBackground(
                                context,
                                selectedIndex,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              child: SizedBox.square(
                                dimension: pawButtonSize,
                                child: KeyedSubtree(
                                  key: _quickActionsTourKey,
                                  child: _buildCentralPawButton(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_tourVisible)
          AppTourOverlay(
            steps: _tourSteps,
            anchorKeys: [
              _homeTourKey,
              _servicesTourKey,
              _quickActionsTourKey,
              _calendarTourKey,
              _profileTourKey,
            ],
            currentStep: _tourStep,
            onNext: _nextTourStep,
            onBack: _previousTourStep,
            onSkip: _completeTour,
          ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Text(
        "You're offline. Some features may be limited.",
        style: TextStyle(
          color: AppTheme.isDark(context)
              ? AppTheme.darkTextPrimary
              : Colors.white,
          fontSize: 13,
        ),
      ),
      leading: Icon(
        Icons.wifi_off_rounded,
        color: AppTheme.isDark(context)
            ? AppTheme.darkTextPrimary
            : Colors.white,
        size: 20,
      ),
      backgroundColor: AppTheme.isDark(context)
          ? AppTheme.darkCard
          : Colors.grey.shade700,
      actions: const [SizedBox.shrink()],
    );
  }

  Widget _buildNavBarBackground(BuildContext context, int selectedIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: isDark
            ? AppTheme.coloredShadow(Colors.black)
            : AppTheme.mediumShadow,
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.divider(context),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildNavItem(
              context,
              0,
              Icons.home_rounded,
              'Home',
              selectedIndex == 0,
              anchorKey: _homeTourKey,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              1,
              Icons.store_rounded,
              'Services',
              selectedIndex == 1,
              anchorKey: _servicesTourKey,
            ),
          ),
          const SizedBox(width: 66),
          Expanded(
            child: _buildNavItem(
              context,
              2,
              Icons.calendar_today_rounded,
              'Events',
              selectedIndex == 2,
              anchorKey: _calendarTourKey,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              3,
              Icons.person_rounded,
              'Profile',
              selectedIndex == 3,
              anchorKey: _profileTourKey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralPawButton(BuildContext context) {
    return Semantics(
      label: 'Quick actions',
      button: true,
      child:
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showQuickActions(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: AppTheme.actionBlueGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.34),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.surfaceBackground(context),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: AppTheme.foregroundOn(AppTheme.actionBlue),
                  size: 31,
                ),
              ),
            ),
          ).animate().scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            duration: 220.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isSelected, {
    GlobalKey? anchorKey,
  }) {
    return Semantics(
      key: anchorKey,
      label: '$label tab',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedContainer(
            duration: 180.ms,
            curve: Curves.easeOutCubic,
            height: 54,
            constraints: const BoxConstraints(maxWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.mutedText(context),
                      size: 23,
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.04, 1.04),
                      duration: 180.ms,
                    ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.mutedText(context),
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _syncTourState() {
    if (!mounted) return;
    final profile = context.read<AuthProvider>().userProfile;
    if (widget.replayTour && !_replayStarted) {
      _replayStarted = true;
      setState(() {
        _tourStep = 0;
        _tourVisible = true;
      });
      return;
    }
    if (!_tourVisible && profile?.needsAppTour == true) {
      setState(() {
        _tourStep = profile!.appTourStep.clamp(0, _tourSteps.length - 1);
        _tourVisible = true;
      });
      return;
    }
    _requestNotificationPermissionIfReady();
  }

  Future<void> _nextTourStep() async {
    if (_tourStep == _tourSteps.length - 1) {
      await _completeTour();
      return;
    }
    final next = _tourStep + 1;
    if (!widget.replayTour) {
      final saved = await context.read<AuthProvider>().saveAppTourStep(next);
      if (!saved) {
        _showTourSaveError();
        return;
      }
    }
    if (mounted) setState(() => _tourStep = next);
  }

  Future<void> _previousTourStep() async {
    if (_tourStep == 0) return;
    final previous = _tourStep - 1;
    if (!widget.replayTour) {
      final saved = await context.read<AuthProvider>().saveAppTourStep(
        previous,
      );
      if (!saved) {
        _showTourSaveError();
        return;
      }
    }
    if (mounted) setState(() => _tourStep = previous);
  }

  Future<void> _completeTour() async {
    final saved = widget.replayTour
        ? true
        : await context.read<AuthProvider>().completeAppTour();
    if (!saved) {
      _showTourSaveError();
      return;
    }
    if (!mounted) return;
    setState(() => _tourVisible = false);
    _requestNotificationPermissionIfReady();
    if (widget.replayTour) context.go('/home');
  }

  void _requestNotificationPermissionIfReady() {
    if (_notificationPermissionRequested || _tourVisible) return;
    _notificationPermissionRequested = true;
    NotificationService().requestPermissions();
  }

  void _showTourSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('We couldn’t save your tour progress. Please try again.'),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/services')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/services');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Future<void> _showQuickActions(BuildContext context) async {
    final router = GoRouter.of(context);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) {
        return QuickActionsSheet(
          onActionSelected: (route) {
            Navigator.of(sheetContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              router.push(route);
            });
          },
        );
      },
    );
  }
}
