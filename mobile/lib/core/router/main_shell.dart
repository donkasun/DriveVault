import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import 'shell_tab_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Allow any widget to request a tab switch via pendingTabProvider.
    ref.listen<int?>(pendingTabProvider, (_, next) {
      if (next != null) {
        navigationShell.goBranch(next);
        ref.read(pendingTabProvider.notifier).clear();
      }
    });

    // Hide the floating tab bar while the keyboard is open so it doesn't sit
    // on top of the keyboard / cover form fields.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          if (!keyboardOpen)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _FloatingTabBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: _TabBarContent(currentIndex: currentIndex, onTap: onTap),
    );
  }
}

class _TabBarContent extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabBarContent({required this.currentIndex, required this.onTap});

  @override
  State<_TabBarContent> createState() => _TabBarContentState();
}

class _TabBarContentState extends State<_TabBarContent> {
  /// Guard against opening multiple quick-add sheets simultaneously.
  bool _quickAddOpen = false;

  static const _iconAssets = [
    'assets/icons/home.svg',
    'assets/icons/garage.svg',
    'assets/icons/expenses.svg',
    'assets/icons/settings.svg',
  ];
  static const _labels = ['Home', 'Garage', 'Expenses', 'Settings'];

  @override
  Widget build(BuildContext context) {
    // Layout: Home · Garage · [center +] · Expenses · Settings.
    // The four tabs flex evenly; the raised add button sits in the middle.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _tab(0)),
        Expanded(child: _tab(1)),
        _centerAddButton(),
        Expanded(child: _tab(2)),
        Expanded(child: _tab(3)),
      ],
    );
  }

  Widget _tab(int index) {
    final active = index == widget.currentIndex;
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: active
              ? _ActiveTab(
                  key: ValueKey('active-$index'),
                  iconAsset: _iconAssets[index],
                  label: _labels[index],
                )
              : _InactiveTab(
                  key: ValueKey('inactive-$index'),
                  iconAsset: _iconAssets[index],
                  label: _labels[index],
                ),
        ),
      ),
    );
  }

  Widget _centerAddButton() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _AddButton(
          key: const Key('fab_quick_add'),
          onPressed: _quickAddOpen
              ? null
              : () async {
                  if (_quickAddOpen) return;
                  setState(() => _quickAddOpen = true);
                  try {
                    await showQuickAddSheet(context);
                  } finally {
                    if (mounted) {
                      setState(() => _quickAddOpen = false);
                    }
                  }
                },
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final String iconAsset;
  final String label;

  const _ActiveTab({super.key, required this.iconAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    // Yellow rounded chip carrying the icon + its label, per the mockup.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(40),
      ),
      child: SvgPicture.asset(
        iconAsset,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _InactiveTab extends StatelessWidget {
  final String iconAsset;
  final String label;

  const _InactiveTab({super.key, required this.iconAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            AppColors.textOnDarkMuted,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDarkMuted,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Prominent, raised yellow circle — the central "add anything" action.
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: AppColors.primary.withValues(alpha: 0.55),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Icon(Icons.add, color: AppColors.textPrimary, size: 34),
        ),
      ),
    );
  }
}
