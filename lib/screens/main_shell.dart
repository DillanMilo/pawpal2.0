import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/connectivity.dart';
import 'quick_actions/quick_actions_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isOffline = false;
  late final StreamSubscription<bool> _connectivitySub;

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
      NotificationService().requestPermissions();
    });
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomInset = bottomPadding > 0 ? bottomPadding : 12.0;
    const navBarHeight = 72.0;
    const pawButtonSize = 66.0;
    const pawButtonOverlap = 29.0;
    const navShellHeight = navBarHeight + pawButtonOverlap;

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (_isOffline)
            MaterialBanner(
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
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset),
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
                child: _buildNavBarBackground(context, selectedIndex),
              ),
              Positioned(
                top: 0,
                child: SizedBox.square(
                  dimension: pawButtonSize,
                  child: _buildCentralPawButton(context),
                ),
              ),
            ],
          ),
        ),
      ),
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
          color: isDark ? AppTheme.darkDivider : AppTheme.dividerColor,
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
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              1,
              Icons.store_rounded,
              'Services',
              selectedIndex == 1,
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
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              3,
              Icons.person_rounded,
              'Profile',
              selectedIndex == 3,
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
                child: const Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),
          ).animate().scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            duration: 380.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return Semantics(
      label: '$label tab',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeInOut,
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
                          : AppTheme.textLight,
                      size: 23,
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                    ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textLight,
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
