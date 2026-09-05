/// Minimal date formatting for the calendar screen — hand-rolled rather
/// than pulling in `intl`, since that's not a confirmed dependency of this
/// project. Monday-start week throughout (`DateTime.weekday`: 1=Monday).
///
/// Month/weekday names are localized via `AppStrings` (`monthFull`/
/// `weekdayFull`/`weekdayShort`) rather than a fixed English-only list —
/// that used to be exactly the bug: switching the app's language (Settings
/// → Language) changed every other label on screen except these, since the
/// old `kMonthNames`/`kWeekdayFull`/`kWeekdayShort` consts here were plain
/// hardcoded English and never consulted `AppStrings.currentLanguageCode`
/// at all.
import '../localization/app_strings.dart';

/// Full month name (1=January ... 12=December) in the active language.
String monthFull(int month) => AppStrings.monthFull(month);

/// Full weekday name (1=Monday ... 7=Sunday, matching `DateTime.weekday`)
/// in the active language.
String weekdayFull(int weekday) => AppStrings.weekdayFull(weekday);

/// Short weekday label (1=Monday ... 7=Sunday) in the active language —
/// e.g. the month grid's "Mon Tue Wed ..." column headers.
String weekdayShort(int weekday) => AppStrings.weekdayShort(weekday);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The Monday that starts the week containing [date].
DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String formatFullDate(DateTime date) {
  return '${weekdayFull(date.weekday)}, ${monthFull(date.month)} ${date.day}';
}

String formatMonthYear(DateTime date) {
  return '${monthFull(date.month)} ${date.year}';
}

String formatWeekRange(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  if (weekStart.month == weekEnd.month) {
    return '${monthFull(weekStart.month)} ${weekStart.day} – ${weekEnd.day}, ${weekEnd.year}';
  }
  return '${monthFull(weekStart.month)} ${weekStart.day} – ${monthFull(weekEnd.month)} ${weekEnd.day}, ${weekEnd.year}';
}

String formatTime(DateTime dt) {
  final hour = dt.hour == 0
      ? 12
      : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
