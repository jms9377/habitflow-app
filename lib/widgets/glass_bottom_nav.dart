import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.activeIcon, required this.label, required this.color});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
}

/// A floating, frosted-glass pill nav bar in the style of iOS's translucent
/// tab bars: blurred/semi-transparent background, a soft border+shadow, and
/// a color pill that slides smoothly to the selected tab.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({super.key, required this.items, required this.index, required this.onTap});

  final List<GlassNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                final activeColor = items[index].color;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * index + 6,
                      top: 6,
                      bottom: 6,
                      width: itemWidth - 12,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: activeColor.withValues(alpha: 0.55)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < items.length; i++)
                          Expanded(
                            child: _GlassNavButton(
                              item: items[i],
                              selected: i == index,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({required this.item, required this.selected, required this.onTap});

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? item.color : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected ? 1 : 0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(scale: 1 + t * 0.15, child: child),
            child: Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
