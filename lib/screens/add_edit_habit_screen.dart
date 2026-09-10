import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_templates.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _paletteGeneral = [0xFF2DD4BF, 0xFF60A5FA, 0xFFA78BFA, 0xFF34D399];
const _paletteTrading = [0xFFF5B342, 0xFFF87171, 0xFFFB923C, 0xFFFACC15];

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key, required this.repository, this.existing});

  final HabitRepository repository;
  final Habit? existing;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _noteController =
      TextEditingController(text: widget.existing?.note ?? '');
  late String _emoji = widget.existing?.emoji ?? '✨';
  late HabitCategory _category = widget.existing?.category ?? HabitCategory.general;
  late int _colorValue = widget.existing?.colorValue ?? _paletteGeneral.first;
  late final Set<int> _activeWeekdays =
      (widget.existing != null && !widget.existing!.isDaily ? widget.existing!.activeWeekdays : const <int>[])
          .toSet();
  // Whether the "every day" mode is active. Defaults to true for a new
  // habit so tapping "Create" without touching this section still
  // produces a sensible daily habit - but crucially, the individual
  // weekday toggles are only ever shown (and only ever start selected)
  // once the user explicitly switches to "Custom days". Previously all
  // seven toggles started pre-selected as the "every day" state, which
  // read as "nothing chosen yet" to most people - tapping a day to
  // "choose" it actually DESELECTED it, silently excluding that day from
  // the schedule (root cause of a habit created this way vanishing from
  // Home's "All"/today list while still showing in Stats, which doesn't
  // filter by schedule).
  late bool _everyDay = widget.existing?.isDaily ?? true;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _applyTemplate(HabitTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _emoji = template.emoji;
      _category = template.category;
      _noteController.text = template.note ?? '';
      _colorValue = (_category == HabitCategory.trading ? _paletteTrading : _paletteGeneral).first;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the habit a name first.')),
      );
      return;
    }
    if (!_everyDay && _activeWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day, or switch to "Every day".')),
      );
      return;
    }

    final provider = context.read<HabitProvider>();
    final weekdays = _everyDay ? const [1, 2, 3, 4, 5, 6, 7] : (_activeWeekdays.toList()..sort());
    final note = _noteController.text.trim();

    if (_isEditing) {
      final habit = widget.existing!;
      habit.name = name;
      habit.emoji = _emoji;
      habit.category = _category;
      habit.colorValue = _colorValue;
      habit.activeWeekdays = weekdays;
      habit.note = note.isEmpty ? null : note;
      await provider.updateHabit(habit);
    } else {
      await provider.addHabit(
        name: name,
        emoji: _emoji,
        category: _category,
        colorValue: _colorValue,
        activeWeekdays: weekdays,
        note: note.isEmpty ? null : note,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final templates =
        _category == HabitCategory.trading ? tradingHabitTemplates : generalHabitTemplates;
    final palette = _category == HabitCategory.trading ? _paletteTrading : _paletteGeneral;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit habit' : 'New habit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _isEditing ? null : () => setState(() => _category = HabitCategory.general),
                child: CategoryChip(category: HabitCategory.general, selected: _category == HabitCategory.general),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isEditing ? null : () => setState(() => _category = HabitCategory.trading),
                child: CategoryChip(category: HabitCategory.trading, selected: _category == HabitCategory.trading),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isEditing) ...[
            Text('Quick templates', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  return ActionChip(
                    avatar: Text(t.emoji),
                    label: Text(t.name),
                    onPressed: () => _applyTemplate(t),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              _EmojiPicker(selected: _emoji, onSelected: (e) => setState(() => _emoji = e)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Habit name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 20),
          Text('Repeat', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RepeatModeButton(
                  label: 'Every day',
                  selected: _everyDay,
                  color: AppColors.forCategory(_category),
                  onTap: () => setState(() => _everyDay = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepeatModeButton(
                  label: 'Custom days',
                  selected: !_everyDay,
                  color: AppColors.forCategory(_category),
                  onTap: () => setState(() => _everyDay = false),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _everyDay
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap the days this habit repeats on',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (int i = 0; i < 7; i++) _WeekdayToggle(
                              label: _weekdayLabels[i],
                              selected: _activeWeekdays.contains(i + 1),
                              color: AppColors.forCategory(_category),
                              onTap: () => setState(() {
                                final day = i + 1;
                                if (_activeWeekdays.contains(day)) {
                                  _activeWeekdays.remove(day);
                                } else {
                                  _activeWeekdays.add(day);
                                }
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final c in palette)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorValue = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: _colorValue == c
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_isEditing ? 'Save changes' : 'Create habit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatModeButton extends StatelessWidget {
  const _RepeatModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : AppColors.surfaceAlt,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

const _emojiOptions = [
  '✨', '💧', '🏃', '📖', '😴', '🧘', '🍬', '🧹', '💡', '📋', '🛡️', '🚫', '📝', '✅', '🛑', '🔍', '💪', '🎯'
];

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (context) => GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            for (final e in _emojiOptions)
              GestureDetector(
                onTap: () {
                  onSelected(e);
                  Navigator.of(context).pop();
                },
                child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
          ],
        ),
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(selected, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
