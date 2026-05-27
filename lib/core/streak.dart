class StreakState {
  const StreakState({required this.count, required this.lastCompletedOn});

  final int count;
  final String? lastCompletedOn;
}

StreakState calculateNextStreak({
  required int currentCount,
  required String? lastCompletedOn,
  required DateTime completedAt,
  required int durationMinutes,
}) {
  if (durationMinutes <= 0) {
    return StreakState(count: currentCount, lastCompletedOn: lastCompletedOn);
  }

  final DateTime completedDate = DateTime(
    completedAt.year,
    completedAt.month,
    completedAt.day,
  );
  final DateTime? previousDate = _parseDateOnly(lastCompletedOn);

  if (previousDate == null) {
    return StreakState(
      count: 1,
      lastCompletedOn: _formatDateOnly(completedDate),
    );
  }

  final int daysSincePrevious = completedDate.difference(previousDate).inDays;
  if (daysSincePrevious == 0) {
    return StreakState(
      count: currentCount,
      lastCompletedOn: _formatDateOnly(completedDate),
    );
  }

  if (daysSincePrevious == 1) {
    return StreakState(
      count: currentCount + 1,
      lastCompletedOn: _formatDateOnly(completedDate),
    );
  }

  return StreakState(count: 1, lastCompletedOn: _formatDateOnly(completedDate));
}

DateTime? _parseDateOnly(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }

  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
