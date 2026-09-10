import 'package:flutter/material.dart';

import '../models/habit_category.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.selected = false});

  final HabitCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCategory(category);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? color : AppColors.border),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: selected ? color : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
