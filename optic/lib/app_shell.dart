import 'dart:async';

import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:optic/widgets/sidebar.dart';
import 'package:optic/widgets/notification_bell.dart';
import 'package:optic/widgets/app_top_bar.dart';
import 'package:optic/controllers/tenant_session.dart';
import 'package:optic/controllers/theme_controller.dart';
import 'package:optic/responsive.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/confirm_dialog.dart';
import 'package:optic/localization/app_strings.dart';

/// Shared by both the desktop sidebar and the mobile/tablet drawer overlay
/// (see [AppShell.build] below). Confirms, then calls the real
/// `TenantSession.signOut()` — `main.dart`'s auth gate is watching
/// `TenantSession` and swaps the whole app over to `LoginScreen` the moment
/// this resolves, so there's nothing left to navigate or acknowledge here
/// (no snackbar: this widget tree is what's about to be torn down).
Future<void> _handleSignOut(BuildContext context) async {
  final confirmed = await showConfirmDialog(
    context: context,
    title: AppStrings.confirmSignOutTitle,
    message: AppStrings.confirmSignOutMessage,
    confirmLabel: AppStrings.confirmSignOutButton,
  );
  if (confirmed != true || !context.mounted) return;
  await context.read<TenantSession>().signOut();
}

/// Wraps [child] with the 5 button-family drop-shadow `ComponentTheme`s
/// (Primary/Outline/Ghost/Link/Destructive), sourced live from
/// [themeController] so the Settings "Button shadow" slider takes effect
/// immediately. Deliberately scoped to just the screen-content area passed
/// in by each call site below — never around `AppDrawer` or the
/// mobile/tablet drawer overlay (`openAppDrawer`, a separate route pushed
/// onto the app's root `Overlay`, outside this widget's subtree either
/// way) — per the "shadow on screens, not the sidebar" follow-up.
Widget _withButtonShadows(ThemeController themeController, Widget child) {
  return ComponentTheme<PrimaryButtonTheme>(
    data: themeController.primaryButtonTheme,
    child: ComponentTheme<OutlineButtonTheme>(
      data: themeController.outlineButtonTheme,
      child: ComponentTheme<GhostButtonTheme>(
        data: themeController.ghostButtonTheme,
        child: ComponentTheme<LinkButtonTheme>(
          data: themeController.linkButtonTheme,
          child: ComponentTheme<DestructiveButtonTheme>(
            data: themeController.destructiveButtonTheme,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Everything a screen needs around its own content: the persistent
/// desktop sidebar (collapsible via its own hamburger), the mobile/tablet
/// overlay drawer (opened via a slim top hamburger bar), and the
/// resize-settle loading state — all in one place, so every screen gets
/// this behavior by wrapping itself in [AppShell] instead of re-building it.
///
/// Usage:
/// ```dart
/// return AppShell(
///   navItems: (context) => buildAppNavItems(context, 'Dashboard'),
///   bodyBuilder: (context, breakpoint) => MyScreenBody(breakpoint: breakpoint),
/// );
/// ```
class AppShell extends StatefulWidget {
  final List<SidebarEntry> Function(BuildContext context) navItems;
  final Widget Function(BuildContext context, Breakpoint breakpoint)
  bodyBuilder;

  const AppShell({super.key, required this.navItems, required this.bodyBuilder});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Desktop-only: whether the persistent sidebar is full width (with
  // labels) or collapsed to an icon rail.
  bool _sidebarExpanded = true;

  // --- Resize-settle handling -------------------------------------------
  // While the window/viewport width is actively changing, we don't want to
  // keep re-laying-out the full screen on every intermediate width. Instead
  // show a loading state and only rebuild once width stops changing for a
  // short debounce window, "landing" on whichever breakpoint it settles into.
  double? _lastObservedWidth;
  bool _isSettlingLayout = false;
  Timer? _resizeDebounce;

  static const _resizeSettleDelay = Duration(milliseconds: 220);

  void _reportWidth(double width) {
    final isFirstObservation = _lastObservedWidth == null;
    final changed =
        _lastObservedWidth == null ||
        (width - _lastObservedWidth!).abs() > 0.5;
    if (!changed) return;

    _lastObservedWidth = width;

    // A first observation isn't a resize — there's nothing to "settle"
    // from — but since every navigation swaps in a brand-new `AppShell`
    // (each screen builds its own, no shared ShellRoute), this is also true
    // on *every single sidebar click*. Previously the debounce Timer below
    // was scheduled unconditionally, so ~220ms after every click it fired
    // `setState(() => _isSettlingLayout = false)` — already false, but
    // `setState` doesn't diff the value, so it forced a second full
    // rebuild of the sidebar, top bar, and whole screen body all over
    // again. That needless extra render pass, not any animation, is what
    // actually read as click "latency". Bailing out here for the first
    // observation skips that entirely; genuine window resizes still hit
    // this same method again with `isFirstObservation == false`.
    if (isFirstObservation) return;

    _resizeDebounce?.cancel();

    if (!_isSettlingLayout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isSettlingLayout) {
          setState(() => _isSettlingLayout = true);
        }
      });
    }

    _resizeDebounce = Timer(_resizeSettleDelay, () {
      if (mounted) setState(() => _isSettlingLayout = false);
    });
  }

  @override
  void dispose() {
    _resizeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final tenantSession = context.watch<TenantSession>();
    final shopName = tenantSession.shopName ?? '';
    return Scaffold(
      // Reads through `ThemeController.backgroundColor` (rather than
      // picking `colorFamily.dark/light.background` straight off, as this
      // used to) so the Background color/opacity setting actually shows up —
      // this Scaffold is the page canvas behind every screen in the app.
      backgroundColor: themeController.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _reportWidth(constraints.maxWidth);

          if (_isSettlingLayout) {
            return const Center(child: material.CircularProgressIndicator());
          }

          final mobile = Responsive.isMobile(context);
          final tablet = Responsive.isTablet(context);
          final desktop = Responsive.isDesktop(context);
          final breakpoint = resolveBreakpoint(
            mobile: mobile,
            tablet: tablet,
            desktop: desktop,
          );
          final navItems = widget.navItems(context);

          if (breakpoint != Breakpoint.desktop) {
            // Mobile/tablet: no inline sidebar — a slim top bar with a
            // hamburger opens it as an overlay instead. Each screen's own
            // body starts right below it. Button shadows are scoped to this
            // whole content area (hamburger/bell + body) — the drawer it
            // opens is a separate overlay route, so it's unaffected either
            // way.
            return _withButtonShadows(
              themeController,
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Button(
                            style: const ButtonStyle.ghost(),
                            onPressed: () => openAppDrawer(
                              context,
                              items: navItems,
                              onSignOut: () => _handleSignOut(context),
                            ),
                            child: const Icon(Icons.menu),
                          ),
                          const NotificationBell(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: widget.bodyBuilder(context, breakpoint),
                    ),
                  ],
                ),
              ),
            );
          }

          // Desktop: sidebar sits inline, permanently, toggling between
          // full width and an icon rail via its own hamburger button.
          // Button shadows wrap only the content side (top bar + body) —
          // `AppDrawer` (the actual sidebar) is a sibling here, deliberately
          // left outside so its buttons stay flat per the "not on the
          // sidebar" follow-up.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDrawer(
                clinicName: shopName,
                items: navItems,
                collapsed: !_sidebarExpanded,
                onToggleCollapse: () =>
                    setState(() => _sidebarExpanded = !_sidebarExpanded),
                onSignOut: () => _handleSignOut(context),
              ),
              Expanded(
                child: _withButtonShadows(
                  themeController,
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top bar, present on every desktop screen — client
                        // search, "+ New" quick actions, notifications, and
                        // the signed-in user, per the redesign brief.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: const AppTopBar(),
                        ),
                        Expanded(
                          child: widget.bodyBuilder(context, breakpoint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
