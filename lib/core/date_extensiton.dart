extension DateTimeComparison on DateTime {
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}
