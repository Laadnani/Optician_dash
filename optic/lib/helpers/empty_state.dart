import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A small "nothing here" card — same shape as the empty state
/// `AppointmentsColumn` already draws for "No appointments on this day",
/// generalized so every tab/section on [ClientFileScreen] (and the
/// clients list) can reuse it instead of re-drawing its own version.
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.mutedForeground),
              const SizedBox(height: 8),
              Text(title).semiBold(),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, textAlign: TextAlign.center).muted(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
