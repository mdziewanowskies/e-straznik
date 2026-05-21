import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../providers/date_range_providers.dart';
import '../theme/colors.dart';

class DateRangePickerBar extends StatelessWidget {
  const DateRangePickerBar({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('d MMM', 'pl_PL');
    final label = '${f.format(range.from)} – ${f.format(range.to)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickRange(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.mutedFg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.mutedFg),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PresetMenu(onSelect: onChanged),
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateRange.earliestAllowed,
      lastDate: now,
      initialDateRange: DateTimeRange(start: range.from, end: range.to),
      locale: const Locale('pl', 'PL'),
      helpText: 'Wybierz zakres dat',
      cancelText: 'Anuluj',
      confirmText: 'OK',
      saveText: 'Zapisz',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.background,
                onSurface: AppColors.foreground,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(DateRange(from: picked.start, to: picked.end));
    }
  }
}

enum _Preset { d1, d7, d30, m3, m12 }

class _PresetMenu extends StatelessWidget {
  const _PresetMenu({required this.onSelect});
  final ValueChanged<DateRange> onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Preset>(
      tooltip: 'Szybki wybór',
      icon: const Icon(Icons.tune, size: 20, color: AppColors.mutedFg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (p) {
        HapticFeedback.selectionClick();
        final now = DateTime.now();
        late DateTime from;
        switch (p) {
          case _Preset.d1:
            from = now.subtract(const Duration(days: 1));
            break;
          case _Preset.d7:
            from = now.subtract(const Duration(days: 7));
            break;
          case _Preset.d30:
            from = now.subtract(const Duration(days: 30));
            break;
          case _Preset.m3:
            from = now.subtract(const Duration(days: 90));
            break;
          case _Preset.m12:
            from = now.subtract(const Duration(days: 365));
            break;
        }
        onSelect(DateRange(from: from, to: now));
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Preset.d1, child: Text('Ostatnia doba')),
        PopupMenuItem(value: _Preset.d7, child: Text('Ostatnie 7 dni')),
        PopupMenuItem(value: _Preset.d30, child: Text('Ostatnie 30 dni')),
        PopupMenuItem(value: _Preset.m3, child: Text('Ostatnie 3 miesiące')),
        PopupMenuItem(value: _Preset.m12, child: Text('Ostatnie 12 miesięcy')),
      ],
    );
  }
}
