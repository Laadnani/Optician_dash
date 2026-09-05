import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' as services;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:optic/controllers/theme_controller.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/add_appointment_dialog.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/client.dart';
import 'package:optic/widgets/notification_bell.dart';
import 'package:optic/widgets/user_avatar.dart';

/// The redesigned desktop top bar: a live client search, a "+ New" quick
/// action menu, the existing [NotificationBell], and a small user avatar
/// (initials) + clinic/doctor name — per the designer brief's "modern
/// application shell" section. Sits inline in [AppShell]'s existing
/// desktop top-bar slot, replacing the bare `NotificationBell()` there.
///
/// Mobile keeps its own minimal hamburger + bell row in [AppShell] — the
/// search/quick-action/avatar cluster is desktop-only, matching how dense
/// top bars like this are normally collapsed on small screens rather than
/// squeezed in.
class AppTopBar extends StatefulWidget {
  const AppTopBar({super.key});

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  final _searchController = material.TextEditingController();
  final _searchFocusNode = material.FocusNode();
  final _layerLink = material.LayerLink();
  material.OverlayEntry? _overlayEntry;

  // Which match Enter jumps to next — advances on every Enter press and
  // wraps back to 0, so repeatedly pressing Enter loops through all
  // matches one at a time instead of always reopening the top result.
  // Reset whenever the query text changes.
  int _matchCursor = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _searchFocusNode.onKeyEvent = _handleKey;
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      // Slight delay so a tap on a result row registers before the
      // overlay is torn down out from under it.
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _onSearchChanged() {
    _matchCursor = 0;
    setState(() {});
    if (_searchFocusNode.hasFocus) _showOverlay();
  }

  List<Client> _matches(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final clients = context.read<DataProvider>().clients;
    return clients
        .where((p) {
          final name = '${p.firstName} ${p.lastName}'.toLowerCase();
          return name.contains(query) ||
              p.fileNumber.toLowerCase().contains(query) ||
              p.phone.toLowerCase().contains(query);
        })
        .take(6)
        .toList();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = material.Overlay.of(context);
    _overlayEntry = material.OverlayEntry(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final matches = _matches(context);
        if (matches.isEmpty && _searchController.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return material.Positioned(
          width: 320,
          child: material.CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: material.Material(
              color: material.Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: material.Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 320),
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(AppStrings.topBarNoResults).muted(),
                      )
                    : material.ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, i) {
                          final client = matches[i];
                          return material.InkWell(
                            // `onTapDown` (fires on pointer-down) rather than
                            // `onTap` (fires on pointer-up, after a full tap
                            // gesture completes): clicking a row first moves
                            // focus away from the search field, which
                            // schedules `_removeOverlay()` ~150ms later via
                            // `_onFocusChanged`. On a slightly-held click
                            // that removal can land mid-gesture, tearing out
                            // the very `OverlayEntry` this InkWell lives in
                            // and cancelling the tap before `onTap` ever
                            // fires — which is why clicking a result
                            // sometimes did nothing. Navigating on
                            // tap-down sidesteps that race entirely.
                            onTapDown: (_) => _openClient(client),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _initials(client),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${client.firstName} ${client.lastName}',
                                        ).small(),
                                        Text(client.fileNumber).muted(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  String _initials(Client client) {
    final first = client.firstName.isNotEmpty ? client.firstName[0] : '';
    final last = client.lastName.isNotEmpty ? client.lastName[0] : '';
    return ('$first$last').toUpperCase();
  }

  void _openClient(Client client) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _removeOverlay();
    context.go('/clients/${client.id}');
  }

  // Pressing Enter while the search field has focus jumps to a client
  // file — same destination as clicking a row in the dropdown, just
  // without a mouse. Unlike a click, Enter deliberately leaves the query
  // and focus alone (no clear/unfocus) so pressing Enter again loops to
  // the *next* match, wrapping back to the first after the last one —
  // useful for stepping through several same-named clients without
  // retyping.
  //
  // Hooked in via `FocusNode.onKeyEvent` rather than wrapping the field in
  // a `KeyboardListener` — a `KeyboardListener` attaches its own `Focus` to
  // the given node, and shadcn's `TextField` attaches that same node again
  // internally for its `EditableText`, which put the node in the focus
  // tree twice and threw "The supplied child is already an ancestor of
  // this node. Loops are not allowed." `onKeyEvent` hooks into the node
  // shadcn's `TextField` already owns instead of adding a second one.
  material.KeyEventResult _handleKey(
    material.FocusNode node,
    services.KeyEvent event,
  ) {
    if (event is! services.KeyDownEvent) {
      return material.KeyEventResult.ignored;
    }
    if (event.logicalKey != services.LogicalKeyboardKey.enter &&
        event.logicalKey != services.LogicalKeyboardKey.numpadEnter) {
      return material.KeyEventResult.ignored;
    }
    final matches = _matches(context);
    if (matches.isEmpty) return material.KeyEventResult.ignored;
    final index = _matchCursor % matches.length;
    _matchCursor = index + 1;
    _removeOverlay();
    context.go('/clients/${matches[index].id}');
    return material.KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The "+ New" button below is a hand-built `Container`, not a real
    // shadcn `Button`, so it never picked up `ThemeData.scaling` the way
    // every other button in the app does — this reads the dedicated
    // Button Scaling setting directly and applies it to this one button's
    // padding/radius/icon/text/spacing.
    final buttonScaling = context.watch<ThemeController>().buttonScaling;

    return Row(
      children: [
        Expanded(
          child: material.CompositedTransformTarget(
            link: _layerLink,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                placeholder: Text(AppStrings.topBarSearchPlaceholder),
                features: [
                  InputFeature.leading(
                    StatedWidget.builder(
                      builder: (context, states) {
                        if (states.hovered) {
                          return const Icon(Icons.search);
                        }
                        return const Icon(
                          Icons.search,
                        ).iconMutedForeground();
                      },
                    ),
                    visibility: InputFeatureVisibility.textEmpty,
                  ),
                  InputFeature.clear(
                    visibility:
                        (InputFeatureVisibility.textNotEmpty &
                            InputFeatureVisibility.focused) |
                        InputFeatureVisibility.hovered,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        material.PopupMenuButton<void>(
          tooltip: '',
          padding: EdgeInsets.zero,
          offset: const Offset(0, 40),
          color: colorScheme.card,
          shape: material.RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.border),
          ),
          itemBuilder: (context) => [
            material.PopupMenuItem<void>(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => showAddAppointmentDialog(context),
              child: Text(AppStrings.quickActionNewAppointment),
            ),
            material.PopupMenuItem<void>(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => context.go('/clients/new'),
              child: Text(AppStrings.quickActionNewClient),
            ),
            material.PopupMenuItem<void>(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => context.go('/quotes'),
              child: Text(AppStrings.topBarNewQuote),
            ),
            material.PopupMenuItem<void>(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => context.go('/orders'),
              child: Text(AppStrings.topBarNewOrder),
            ),
          ],
          // A real `Button` here would need its own `onPressed`, but the tap
          // target and menu are already provided by the enclosing
          // `PopupMenuButton` — a styled, non-interactive container avoids
          // fighting that with a second (disabled-looking) gesture layer.
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * buttonScaling,
              vertical: 9 * buttonScaling,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8 * buttonScaling),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16 * buttonScaling,
                  color: colorScheme.primaryForeground,
                ),
                SizedBox(width: 6 * buttonScaling),
                Text(
                  AppStrings.topBarNewButton,
                  style: TextStyle(color: colorScheme.primaryForeground),
                ).small(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        const NotificationBell(),
        const SizedBox(width: 8),
        // Just the avatar (+ online/offline dot) now — no name/business
        // name text next to it, changeable from Settings > Account.
        const UserAvatar(),
      ],
    );
  }
}
