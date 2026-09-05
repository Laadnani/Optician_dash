import 'package:flutter/material.dart';
// Prefixed on purpose: this file otherwise deliberately only depends on
// plain Material (see the class doc below), and shadcn_flutter defines its
// own `ColorScheme` — importing it unprefixed alongside material.dart's
// would make `ColorScheme` an ambiguous, unresolvable import. The prefix
// is only needed for the type below; callers already hold a
// `shadcn_flutter.ColorScheme` from `Theme.of(context).colorScheme`.
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../localization/app_strings.dart';

/// Single source of truth for "what does this status word look like" —
/// shared by every card with a raw status string (appointments, lab
/// orders, imaging orders, invoices) so the same word reads the same
/// color and the same translated label everywhere instead of each card
/// inventing its own mapping (which is how the app ended up with plain,
/// un-colored "Status: pending" text lines before this).
///
/// Case-insensitive on [status] since it's a free-form `String` field on
/// several models (not an enum) — matches however the mock/real data
/// happens to be cased. Falls back to showing the raw value, muted,
/// rather than silently dropping an unrecognized status.
(String, Color) statusChipStyle(String status, shadcn.ColorScheme colors) {
  switch (status.toLowerCase()) {
    case 'scheduled':
      return (AppStrings.statusScheduled, colors.primary);
    case 'completed':
      return (AppStrings.statusCompleted, Colors.green.shade700);
    case 'paid':
      return (AppStrings.statusPaid, Colors.green.shade700);
    case 'cancelled':
      return (AppStrings.statusCancelled, colors.destructive);
    case 'pending':
      return (AppStrings.statusPending, Colors.orange.shade700);
    default:
      return (status, colors.mutedForeground);
  }
}

/// A small colored pill for status/priority labels.
///
/// Built from plain Material primitives (Container + Text) instead of
/// ShadBadge so we have full control over arbitrary status colors without
/// depending on ShadBadge's more limited built-in variants.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
