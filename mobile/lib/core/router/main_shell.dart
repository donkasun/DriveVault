import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
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

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
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
  static const _iconAssets = [
    'assets/icons/garage.svg',
    'assets/icons/dashboard.svg',
    'assets/icons/settings.svg',
  ];
  static const _labels = ['Garage', 'Home', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / 3;
        final pillWidth = slotWidth - 16;
        final pillLeft = widget.currentIndex * slotWidth + 8;

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
            // Tab items rendered above the pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(3, (index) {
                final isSelected = index == widget.currentIndex;
                return Expanded(
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
                            isSelected ? AppColors.onPrimary : Colors.grey.shade500,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.onPrimary : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

