import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/pending_task.dart';
import '../localization/app_strings.dart';

class PendingTasksPanel extends StatelessWidget {
  final String title;
  final List<PendingTask> items;
  final VoidCallback? onSeeAll;

  /// Optional: called when a task row itself is tapped (not "See all").
  /// Wire this to navigate to the task's source record via
  /// `item.sourceId`/`item.kind` once those detail screens exist.
  final void Function(PendingTask item)? onTapItem;

  const PendingTasksPanel({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.onTapItem,
  });

  /// Icon + color for a task's kind, in one place instead of two separate
  /// switches. Still a real `switch` (not a lookup map) so the compiler
  /// forces every new [PendingTaskKind] case to be handled here too.
  (IconData, Color) _styleFor(PendingTaskKind kind, ColorScheme colors) {
    switch (kind) {
      case PendingTaskKind.signature:
        return (Icons.draw_outlined, Colors.orange.shade600);
    }
  }

  Widget _row(PendingTask item, ColorScheme colors) {
    final (icon, color) = _styleFor(item.kind, colors);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title).small(),
                Text(item.subtitle).muted(),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTapItem == null) return row;
    return GestureDetector(onTap: () => onTapItem!(item), child: row);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title).semiBold(),
        if (onSeeAll != null)
          Button.link(onPressed: onSeeAll, child: Text(AppStrings.pendingTasksSeeAll)),
      ],
    );

    // Same bounded/unbounded adaptation as `AppointmentsColumn`, so this
    // card doesn't overflow when `DashboardMainSection` stretches all
    // three dashboard cards to a shared fixed height on desktop — see
    // that widget's build() for the full reasoning.
    return Card(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxHeight.isFinite;

          if (items.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(AppStrings.pendingTasksEmpty).muted(),
                ),
              ],
            );
          }

          final rows = items.map((item) => _row(item, theme.colorScheme)).toList();
          final body = bounded
              ? ListView(padding: EdgeInsets.zero, children: rows)
              : Column(children: rows);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 4),
              bounded ? Expanded(child: body) : body,
            ],
          );
        },
      ),
    );
  }
}
