import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DotRow extends StatelessWidget {
  const DotRow({
    super.key,
    required this.activeDays,
    required this.onDayTap,
  });

  final Set<String> activeDays;
  final ValueChanged<String> onDayTap;

  static final _fmt = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Rolling 7 days ending today (oldest first)
    final days = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: days.map((day) {
        final key = _fmt.format(day);
        final isActive = activeDays.contains(key);
        final isToday = _fmt.format(today) == key;

        return GestureDetector(
          onTap: () => onDayTap(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dayLabel(day),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _dayLabel(DateTime d) {
    return const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
  }
}
