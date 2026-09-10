import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';

/// A single habit row: emoji, name, streak flame, and a tappable
/// completion circle that pops with a scale animation and morphs into a
/// checkmark. Long-press or tap the row (not the circle) to open details.
class HabitTile extends StatefulWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.completed,
    required this.streak,
    required this.onToggle,
    required this.onOpen,
  });

  final Habit habit;
  final bool completed;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0.0,
    upperBound: 0.15,
  );

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onToggle();
    await _popController.forward();
    await _popController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCategory(widget.habit.category);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'habit-emoji-${widget.habit.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(widget.habit.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.habit.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (widget.streak > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.streak} día${widget.streak == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              key: ValueKey('toggle-${widget.habit.id}'),
              onTap: _handleTap,
              child: AnimatedBuilder(
                animation: _popController,
                builder: (context, child) {
                  final scale = 1 + _popController.value;
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.completed ? color : Colors.transparent,
                    border: Border.all(
                      color: widget.completed ? color : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: widget.completed
                        ? const Icon(Icons.check, size: 18, color: Colors.black, key: ValueKey('done'))
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
