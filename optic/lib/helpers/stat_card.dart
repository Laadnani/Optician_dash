import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:optic/controllers/theme_controller.dart';

/// A compact KPI tile, e.g. "Today's clients: 12".
///
/// Flat leading-icon + text layout. Text readability is the priority:
///  - the icon stays modest-sized so it doesn't eat into the text column's
///    width
///  - the text column gets `Expanded` + `start` alignment (not `stretch`,
///    and no `.expanded()` on the label itself — wrapping a `Text` in its
///    own `Expanded` inside a `mainAxisSize.max` Column is what was forcing
///    the label into a tall, narrow strip instead of reading left-to-right)
///  - font sizes still scale with the card's width, but are clamped to a
///    readable floor/ceiling so they never shrink to illegible or blow up
///    too large
///  - wrapped in `FittedBox(fit: BoxFit.scaleDown)` as a hard guarantee:
///    the manual scale math above gives nice proportions across the normal
///    range of cell sizes, but breaks down in pathological cases (e.g. a
///    4-column square grid crammed onto a phone screen, leaving a cell
///    only ~9px wide) — `_minScale` alone can't shrink far enough to fit
///    that, so `FittedBox` is what actually prevents the overflow, no
///    matter how small the cell ends up being.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// Optional — when set, the whole tile becomes a tap target (e.g. Frame
  /// Inventory's "Out of stock" KPI tapping through to scroll-and-highlight
  /// the matching frame card via `HeartbeatHighlight`). `null` keeps the
  /// tile purely decorative, same as before this was added.
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  // Reference width this design was tuned at. Scale is 1.0 here; it grows
  // above that on wider cards and shrinks below it on narrower ones.
  static const double _referenceWidth = 220;
  static const double _minScale = 0.85;
  static const double _maxScale = 1.2;

  @override
  Widget build(BuildContext context) {
    final iconScaling = context.watch<ThemeController>().iconScaling;
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : _referenceWidth;
            final scale = (width / _referenceWidth).clamp(
              _minScale,
              _maxScale,
            );

            // Readable floor/ceiling regardless of scale.
            final valueSize = (18 * scale).clamp(15.0, 22.0);
            final labelSize = (13 * scale).clamp(11.5, 15.0);

            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: accent, size: 22 * scale * iconScaling),
                  SizedBox(width: 12 * scale),
                  SizedBox(
                    // FittedBox gives its child unbounded/loose
                    // constraints to measure against, so the text column
                    // needs an explicit width here (it can no longer rely
                    // on Expanded, which needs a bounded parent) — sized
                    // to whatever the card's actual available width is,
                    // so it still wraps/ellipsizes the same as before in
                    // normal-sized cells. Reserved icon width still uses
                    // the un-user-scaled `22 * scale` on purpose — it's a
                    // layout-space reservation, not the drawn icon size, so
                    // it doesn't need to track `iconScaling` (the icon is
                    // small enough relative to its box that FittedBox
                    // absorbs the difference either way).
                    width: (width - 22 * scale - 12 * scale).clamp(
                      40.0,
                      double.infinity,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: valueSize),
                        ).bold(),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: labelSize, height: 1.25),
                        ).muted(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (onTap == null) return card;
    // Same `material.InkWell`-over-shadcn-`Card` convention every other
    // tappable dashboard card in this app already uses (see
    // `dashboard_widgets.dart`'s `_tappable`) — kept local here rather than
    // importing that private helper, since this is the only widget in this
    // file that needs it.
    return material.InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}
