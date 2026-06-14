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
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 6),
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

  static const _addSlotWidthFactor = 0.72;
  static const _iconAssets = [
    'assets/icons/home.svg',
    'assets/icons/garage.svg',
    'assets/icons/expenses.svg',
    'assets/icons/settings.svg',
  ];
  static const _labels = ['Home', 'Garage', 'Expenses', 'Settings'];
  static const _tabSlots = [0, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / 5;
        final pillWidth = slotWidth - 16;
        final pillLeft = _tabSlots[widget.currentIndex] * slotWidth + 8;

        return Stack(
          children: [
            // Single pill that slides between tabs
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: pillLeft,
              top: 8,
              bottom: 8,
              width: pillWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            // Tab items rendered above the pill, with a center add slot.
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < _labels.length; index++) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            _iconAssets[index],
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              index == widget.currentIndex
                                  ? AppColors.onPrimary
                                  : Colors.grey.shade500,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: index == widget.currentIndex
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: index == widget.currentIndex
                                  ? AppColors.onPrimary
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index == 1)
                    SizedBox(
                      width: slotWidth * _addSlotWidthFactor,
                      child: Center(
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
                    ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add, color: AppColors.onPrimary, size: 22),
        ),
      ),
    );
  }
}
