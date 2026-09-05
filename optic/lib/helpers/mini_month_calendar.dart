import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as mat;

/// A compact month calendar for picking "the day" the dashboard shows.
///
/// Deliberately built with plain Material widgets (GridView + InkWell)
/// rather than `ShadCalendar`: it keeps this widget's public API
/// (`selectedDate`, `onDateSelected`, `datesWithAppointments`) stable and
/// under our control, while still being painted with the app's Shadcn
/// color scheme so it sits visually inside a ShadCard seamlessly.
///
/// If you'd rather use the package's built-in `ShadCalendar` widget,
/// it's a drop-in alternative for the grid below — check its API against
/// the `shadcn_ui` version pinned in your pubspec, since calendar/date
/// components tend to gain options between releases.
class MiniMonthCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Dates (normalized to midnight) that have at least one appointment,
  /// used to draw a small dot under the day number.
  final Set<DateTime> datesWithAppointments;

  const MiniMonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.datesWithAppointments = const {},
  });

  @override
  State<MiniMonthCalendar> createState() => _MiniMonthCalendarState();
}

class _MiniMonthCalendarState extends State<MiniMonthCalendar> {
  late DateTime _visibleMonth;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(covariant MiniMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    if (newMonth != _visibleMonth) {
      _visibleMonth = newMonth;
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<DateTime?> _daysInGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // Monday = 1 ... Sunday = 7 -> convert to a 0-based leading blank count.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final cells = <DateTime?>[];
    cells.addAll(List.filled(leadingBlanks, null));
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    // Pad to a full number of weeks for a stable grid height.
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final today = DateTime.now();
    final cells = _daysInGrid();
    final numRows = cells.length ~/ 7;
    final monthLabel =
        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(monthLabel).semiBold(),
        Row(
          children: [
            IconButton.ghost(
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: () => _changeMonth(-1),
            ),
            IconButton.ghost(
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ],
    );

    final weekdayRow = Row(
      children: _weekdayLabels
          .map(
            (w) => Expanded(
              child: Center(
                child: Text(w).semiBold(),
              ),
            ),
          )
          .toList(),
    );

    Widget buildGrid({double? aspectRatio, required bool shrinkWrap}) {
      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: aspectRatio ?? 1.0,
        ),
        itemBuilder: (context, index) {
          final date = cells[index];
          if (date == null) return const SizedBox.shrink();

          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isSameDay(date, today);
          final hasAppointments = widget.datesWithAppointments.any(
            (d) => _isSameDay(d, date),
          );

          return mat.Padding(
            padding: const EdgeInsets.all(2),
            child: mat.Material(
              color: isSelected ? colors.primary : Colors.transparent,
              shape: const CircleBorder(),
              child: mat.InkWell(
                customBorder: const CircleBorder(),
                onTap: () => widget.onDateSelected(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? colors.primaryForeground
                            : (isToday
                                ? colors.primary
                                : colors.foreground),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 4,
                      width: 4,
                      child: hasAppointments
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primaryForeground
                                    : colors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // A plain `Column` always hands a non-flex child (the grid) an
    // *unbounded* main-axis constraint, no matter how tall the Column's
    // own incoming constraint is — so a fixed-height grid (aspect ratio
    // 1.0 cells) could ask for more room than a fixed-height dashboard
    // card actually has (a 6-week month vs. a 4-5-week one) and silently
    // overflow. `LayoutBuilder` here detects the two real cases this
    // widget is used in:
    //  - Bounded (desktop dashboard card, fixed height): the grid goes in
    //    an `Expanded` and gets a `childAspectRatio` computed from
    //    whatever height `Expanded` actually gives it, so all `numRows`
    //    rows always fit exactly — no overflow regardless of month length
    //    or the user's Widget/Text/Icon scaling settings.
    //  - Unbounded (mobile/tablet stacked layout, settings preview, any
    //    other unconstrained host): falls back to the original
    //    shrink-wrapped, square-celled grid that grows with its content.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight.isFinite;
        if (!bounded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 4),
              weekdayRow,
              const SizedBox(height: 4),
              buildGrid(shrinkWrap: true),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            header,
            const SizedBox(height: 4),
            weekdayRow,
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, gridConstraints) {
                  final cellWidth = gridConstraints.maxWidth / 7;
                  final cellHeight = gridConstraints.maxHeight / numRows;
                  final aspectRatio =
                      cellHeight > 0 ? cellWidth / cellHeight : 1.0;
                  return buildGrid(
                    aspectRatio: aspectRatio,
                    shrinkWrap: false,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
