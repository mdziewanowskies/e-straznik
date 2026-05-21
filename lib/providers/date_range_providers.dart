import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateRange {
  const DateRange({required this.from, required this.to});
  final DateTime from;
  final DateTime to;

  DateRange copyWith({DateTime? from, DateTime? to}) =>
      DateRange(from: from ?? this.from, to: to ?? this.to);

  /// Najdalsza historia jaką wolno wybrać — 12 miesięcy wstecz.
  static DateTime get earliestAllowed =>
      DateTime.now().subtract(const Duration(days: 365));

  static DateRange power15MinDefault() {
    final now = DateTime.now();
    return DateRange(
      from: now.subtract(const Duration(days: 2)),
      to: now,
    );
  }

  static DateRange readingsDefault() {
    final now = DateTime.now();
    return DateRange(
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
  }
}

final powerDateRangeProvider =
    StateProvider.family<DateRange, String>((ref, _) {
  return DateRange.power15MinDefault();
});

final readingsDateRangeProvider =
    StateProvider.family<DateRange, String>((ref, _) {
  return DateRange.readingsDefault();
});
