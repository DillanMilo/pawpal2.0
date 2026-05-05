import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    const navBarHeight = 78.0;
    const pawButtonSize = 72.0;
    const pawButtonOverlap = 32.0;
    const navShellHeight = navBarHeight + pawButtonOverlap;

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (_isOffline)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: const Text(
                "You're offline. Some features may be limited.",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              leading: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              backgroundColor: Colors.grey.shade700,
              actions: const [SizedBox.shrink()],
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.inkColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.mediumShadow,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
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
          const SizedBox(width: 72),
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.inkColor.withValues(alpha: 0.24),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.softLavender,
                        width: 6,
                      ),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppTheme.inkColor,
                      size: 36,
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 1500.ms,
                curve: Curves.easeInOut,
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
            height: 52,
            constraints: const BoxConstraints(maxWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.inkColor
                          : Colors.white.withValues(alpha: 0.66),
                      size: 25,
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.12, 1.12),
                    ),
                SizedBox(
                  height: 14,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: 180.ms,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.inkColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
