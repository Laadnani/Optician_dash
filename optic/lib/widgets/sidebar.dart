import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../localization/app_strings.dart';
import '../controllers/tenant_session.dart';
import '../controllers/theme_controller.dart';

/// Base type for anything [AppDrawer] can render in its scrollable item
/// list — either a tappable [DrawerItem] or a non-interactive
/// [DrawerSectionHeader] grouping the items below it. Sealed so the
/// itemBuilder's switch stays exhaustive as this grows.
sealed class SidebarEntry {
  const SidebarEntry();
}

/// A single navigation entry in [AppDrawer].
class DrawerItem extends SidebarEntry {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
}

/// A non-interactive small-caps label grouping the [DrawerItem]s that
/// follow it — e.g. "Products & Inventory" above Frames/Lenses/Contact
/// Lenses/Accessories. Skipped entirely in collapsed (icon-rail) mode:
/// there's no room for a label at 72px, so [_SectionHeaderTile] renders a
/// thin divider there instead to keep some visual separation between
/// groups without needing text.
class DrawerSectionHeader extends SidebarEntry {
  final String label;
  const DrawerSectionHeader(this.label);
}

/// Side navigation — follows `ThemeController` fully (color family *and*
/// dark/light mode), same as the rest of the app, so switching "Color
/// scheme" in Settings recolors the sidebar too instead of leaving it
/// pinned to one family.
///
/// Works in two shapes, controlled entirely by [collapsed]:
///  - expanded (280px): brand + labelled nav items — used as the desktop
///    persistent sidebar, and inside the mobile/tablet overlay.
///  - collapsed (72px, icon rail): used only on desktop, when the user
///    clicks the hamburger to shrink the sidebar out of the way.
///
/// [onToggleCollapse] is what the hamburger button (living in this widget's
/// own header) calls — on desktop that flips [collapsed], and inside the
/// mobile/tablet overlay it's wired to close the overlay instead (see
/// `openAppDrawer` below). This widget doesn't know or care which; it just
/// calls the callback.
class AppDrawer extends StatelessWidget {
  final String clinicName;
  final List<SidebarEntry> items;
  final VoidCallback? onSignOut;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  const AppDrawer({
    super.key,
    // No hardcoded default — clinicName is data (the shop's business name),
    // not UI copy, so it's required here and sourced from the session/
    // profile layer at the call site instead.
    required this.clinicName,
    required this.items,
    this.onSignOut,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  static const double expandedWidth = 280;
  static const double collapsedWidth = 72;
  static const Duration _animationDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final colorScheme = themeController.isDarkMode
        ? themeController.colorFamily.dark
        : themeController.colorFamily.light;
    final iconScaling = themeController.iconScaling;

    return Theme(
      data: ThemeData(colorScheme: colorScheme, radius: 1.5),
      // AnimatedContainer + clipBehavior: hardEdge is the overflow guard —
      // whatever the width is mid-animation, content that hasn't caught up
      // yet gets clipped to the box instead of painting outside it.
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeInOut,
        width: collapsed ? collapsedWidth : expandedWidth,
        height: double.infinity,
        // `themeController.backgroundColor` (not the raw `colorScheme.
        // background` above) so the Background color/opacity setting reaches
        // the sidebar too — everything else in this local `Theme` (nav
        // item text/icon colors) is unaffected, only this one backdrop.
        color: themeController.backgroundColor,
        clipBehavior: Clip.hardEdge,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(colorScheme, iconScaling),
              _rule(colorScheme),
              Expanded(
                // Reverted back to the original lazy `ListView.separated`.
                // The eager `SingleChildScrollView(child: Column(...))` swap
                // (plus the ensureVisible-on-selected logic it was there to
                // support) was meant to focus the selected item on
                // navigation, but building + laying out every tile on every
                // single AppDrawer rebuild — which happens on every
                // navigation, since each screen mounts a fresh `AppShell` —
                // was the rebuild cost showing up as click latency. Per
                // request, prioritizing snappy navigation over that
                // focus-the-selected-item nicety: back to lazy, on-demand
                // item building, with the "jumps to top" cosmetic quirk
                // accepted rather than fixed.
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: collapsed ? 8 : 12,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) => _entryTile(
                    items[i],
                    colorScheme,
                    collapsed,
                    iconScaling,
                    i == 0,
                  ),
                ),
              ),
              _rule(colorScheme),
              Padding(
                padding: EdgeInsets.all(collapsed ? 8 : 12),
                child: _DrawerTile(
                  item: DrawerItem(
                    label: AppStrings.sidebarSignOut,
                    icon: Icons.logout_outlined,
                    onTap: onSignOut ?? () {},
                  ),
                  colorScheme: colorScheme,
                  collapsed: collapsed,
                  iconScaling: iconScaling,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Below this width, the expanded header's fixed-size children (40px logo
  // + 12px spacer + toggle button) don't fit no matter how little the
  // Expanded text is squeezed — steady-state collapsed (~72px) is well
  // under this, steady-state expanded (280px) well over it, so this only
  // ever matters mid-animation.
  static const double _expandedHeaderMinWidth = 160;

  Widget _header(ColorScheme colorScheme, double iconScaling) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Driven by the *live* width, not just the `collapsed` flag: the
        // flag flips instantly when the toggle is pressed, but
        // `AnimatedContainer`'s width takes 200ms to catch up. Branching on
        // the flag alone means asking for the full-width layout's fixed
        // children while the box is still animating from ~72px, which
        // throws a RenderFlex overflow on every frame until the animation
        // finishes. Checking the real constraint keeps the two in sync.
        final showExpanded =
            !collapsed && constraints.maxWidth >= _expandedHeaderMinWidth;

        if (!showExpanded) {
          // Collapsed (or mid-collapse): just the toggle button, centered —
          // no brand text to fit into a narrow rail, so nothing to overflow.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Button(
                style: const ButtonStyle.ghost(),
                onPressed: onToggleCollapse,
                child: Icon(Icons.menu, size: 24 * iconScaling),
              ),
            ),
          );
        }

        // Expanded: icon avatar (fixed) + text (Expanded, so it's bounded
        // and ellipsizes instead of overflowing) + the toggle button (fixed).
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              // The app's real logo — replaces the old generic eye-icon-in-
              // a-tinted-circle placeholder. No background container: the
              // logo is already a complete, full-color mark, so wrapping it
              // in another tinted shape would just compete with it.
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  clinicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).semiBold(),
              ),
              if (onToggleCollapse != null)
                Button(
                  style: const ButtonStyle.ghost(),
                  onPressed: onToggleCollapse,
                  child: Icon(Icons.menu, size: 24 * iconScaling),
                ),
            ],
          ),
        );
      },
    );
  }

  // A thin 1px rule instead of a Divider widget — avoids guessing whether
  // shadcn_flutter's own divider/separator component is named `Divider`,
  // `Separator`, etc. Guaranteed to compile and match the theme.
  Widget _rule(ColorScheme colorScheme) =>
      Container(height: 1, color: colorScheme.border);

  // Renders one nav-list entry — a header or a tappable item — factored out
  // of `ListView.separated`'s `itemBuilder` above just to keep that call
  // site short.
  Widget _entryTile(
    SidebarEntry entry,
    ColorScheme colorScheme,
    bool collapsed,
    double iconScaling,
    bool isFirst,
  ) {
    return switch (entry) {
      DrawerSectionHeader() => _SectionHeaderTile(
        header: entry,
        colorScheme: colorScheme,
        collapsed: collapsed,
        // A header right at the very top (no group above it yet) doesn't
        // need the usual "gap from the previous group" spacing above it.
        isFirst: isFirst,
      ),
      DrawerItem() => _DrawerTile(
        item: entry,
        colorScheme: colorScheme,
        collapsed: collapsed,
        iconScaling: iconScaling,
      ),
    };
  }
}

class _DrawerTile extends StatelessWidget {
  final DrawerItem item;
  final ColorScheme colorScheme;
  final bool collapsed;
  final double iconScaling;

  const _DrawerTile({
    required this.item,
    required this.colorScheme,
    this.collapsed = false,
    this.iconScaling = 1.0,
  });

  // Below this width, the icon (up to ~30px with scaling) + 12px spacer
  // don't fit no matter how little the Expanded label is squeezed —
  // steady-state collapsed (~72px rail) is well under this, steady-state
  // expanded (~280px) well over it, so this only ever matters mid-animation.
  static const double _labelMinWidth = 100;

  @override
  Widget build(BuildContext context) {
    // No more ensureVisible-on-selected here — reverted along with the
    // eager list above. The sidebar no longer tries to scroll the selected
    // item into view on navigation; it just renders at whatever scroll
    // offset a fresh `ListView` starts at.
    final iconSize = 20 * iconScaling;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Driven by the *live* width, not just the `collapsed` flag — see
        // `AppDrawer._header`'s matching comment. `collapsed` flips
        // instantly on toggle while the sidebar's `AnimatedContainer`
        // width takes 200ms to catch up, and this tile sits directly in
        // that resizing column via a plain `ListView`, so it sees the same
        // transient narrow widths. Sizing off the real constraint instead
        // of the flag is what actually fixed the overflow (clipping the
        // `AnimatedContainer` only hid it visually — the layout assertion
        // still fired every frame).
        final showLabel = !collapsed && constraints.maxWidth >= _labelMinWidth;
        return Button(
          style: item.selected
              ? const ButtonStyle.primary()
              : const ButtonStyle.ghost(),
          onPressed: item.onTap,
          alignment: showLabel ? Alignment.centerLeft : Alignment.center,
          // Icon-only: no Expanded/Text at all — nothing that could need to
          // shrink or ellipsize, so nothing that can overflow.
          child: !showLabel
              ? Icon(item.icon, size: iconSize)
              : Row(
                  children: [
                    Icon(item.icon, size: iconSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Renders a [DrawerSectionHeader] — a small-caps muted label when expanded,
/// or (since there's no room for text at 72px) a thin divider when
/// collapsed, so the icon rail still shows *some* separation between
/// groups instead of one undifferentiated column of icons.
class _SectionHeaderTile extends StatelessWidget {
  final DrawerSectionHeader header;
  final ColorScheme colorScheme;
  final bool collapsed;
  final bool isFirst;

  const _SectionHeaderTile({
    required this.header,
    required this.colorScheme,
    required this.collapsed,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      if (isFirst) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(height: 1, color: colorScheme.border),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12, isFirst ? 4 : 16, 12, 4),
      child: Text(
        header.label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Presenting the drawer as a mobile/tablet overlay
// ---------------------------------------------------------------------------
//
// Only used on mobile/tablet (see navigation.dart) — the desktop sidebar is
// rendered inline instead, with `collapsed` toggling its width in place.
//
// Uses Flutter's own `Navigator` + `PageRouteBuilder` rather than a guessed
// shadcn_flutter overlay call, so it's guaranteed to compile regardless of
// your installed shadcn_flutter version.

void openAppDrawer(
  BuildContext context, {
  required List<SidebarEntry> items,
  VoidCallback? onSignOut,
}) {
  // Read once, before pushing the route — `TenantSession` doesn't change
  // mid-overlay, so there's no need for the overlay's own subtree to watch
  // it (and `routeContext` below is a fresh context under a `Navigator`
  // push, not guaranteed to sit under every ancestor Provider the same way
  // depending on how it's mounted — reading from the caller's own
  // `context` here sidesteps that entirely).
  final tenantSession = context.read<TenantSession>();
  final clinicName = tenantSession.shopName ?? '';
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: AppDrawer(
            clinicName: clinicName,
            items: items,
            onSignOut: onSignOut,
            // Tapping the hamburger inside the open overlay retracts it —
            // there's no "collapsed rail" concept in overlay mode, closing
            // is the equivalent action.
            onToggleCollapse: () => Navigator.of(routeContext).pop(),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: offset, child: child);
      },
    ),
  );
}
