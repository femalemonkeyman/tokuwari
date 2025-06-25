extension DurationExtension on Duration {
  /// Returns clamp of [Duration] between [min] and [max].
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Returns a [String] representation of [Duration].
  String label({Duration? reference}) {
    reference ??= this;
    int days = inDays;
    int hours = inHours - (days * 24);
    int minutes = inMinutes - (inHours * 60);
    int seconds = inSeconds - (inMinutes * 60);
    if (reference > const Duration(days: 1)) {
      return '${days.toString().padLeft(3, '0')}:'
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else if (reference > const Duration(hours: 1)) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
