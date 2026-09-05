import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/constants.dart';
import 'package:optic/helpers/breakpoint.dart';

/// Shared panel shell for every dashboard section (Attention, Tasks,
/// Appointments, Sales, Recent Activity, Inventory, Quick Actions) — a
/// plain [Container] rather than a themed shadcn [Card], since the
/// redesign wants an exact 16px radius / 1px border / no shadow regardless
/// of whatever the app-wide `ThemeController.cardTheme` scale currently
/// resolves to (see `DashboardTokens`). Every other screen in the app
/// keeps using shadcn's own `Card` untouched.
class DashboardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const DashboardPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final panel = Container(
      padding: padding ?? const EdgeInsets.all(DashboardTokens.cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(DashboardTokens.radius),
        border: Border.all(
          color: colorScheme.border,
          width: DashboardTokens.borderWidth,
        ),
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return material.InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.radius),
      child: panel,
    );
  }
}

/// A panel's header row — title (+ optional leading icon) on the left,
/// "View all →" (or any trailing action) on the right. Used by every
/// dashboard panel below instead of each one hand-rolling its own header
/// Row, so the "View all →" link pattern (redesign brief point 14) stays
/// visually identical everywhere it appears.
class DashboardPanelHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DashboardPanelHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: colorScheme.mutedForeground),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        if (actionLabel != null)
          material.InkWell(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground, fontWeight: FontWeight.w500),
                ),
                Icon(Icons.arrow_forward, size: 13, color: colorScheme.mutedForeground),
              ],
            ),
          ),
      ],
    );
  }
}

/// Arranges two panels for a given [breakpoint] — desktop splits them
/// asymmetrically (60/40 by default, matching every panel pair in the
/// redesign brief: Tasks/Appointments, Sales/Activity, Inventory/Quick
/// Actions), tablet and mobile both stack them full-width. Either slot can
/// be `null` (its widget toggled off elsewhere) without leaving a gap.
class DashboardPanelPair extends StatelessWidget {
  final Breakpoint breakpoint;
  final Widget? left;
  final Widget? right;
  final int leftFlex;
  final int rightFlex;

  const DashboardPanelPair({
    super.key,
    required this.breakpoint,
    this.left,
    this.right,
    this.leftFlex = 3,
    this.rightFlex = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (left == null && right == null) return const SizedBox.shrink();
    if (left == null) return right!;
    if (right == null) return left!;

    if (breakpoint == Breakpoint.desktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: leftFlex, child: left!),
            const SizedBox(width: DashboardTokens.sectionGap),
            Expanded(flex: rightFlex, child: right!),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        left!,
        const SizedBox(height: DashboardTokens.sectionGap),
        right!,
      ],
    );
  }
}
