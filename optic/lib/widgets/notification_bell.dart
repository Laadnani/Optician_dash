import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../controllers/notifications_controller.dart';
import '../data/data_provider.dart';
import '../data/dashboard_repository.dart';
import '../localization/app_strings.dart';
import '../models/pending_task.dart';

/// Global notification bell — lives in [AppShell] so it shows on every
/// screen (dashboard, clients, calendar, settings, ...), matching the
/// always-present top bar from the Figma reference this was built against.
///
/// Notifications are NOT a separate feed: the dropdown below shows exactly
/// [derivePendingTasks] — the same "needs your attention" items the
/// dashboard's `PendingTasksPanel` shows — so there's one source of truth
/// instead of two lists that could drift apart. This widget only adds
/// read/unread state on top (via [NotificationsController]) and turns each
/// row into something tappable.
///
/// Falls back to `material.PopupMenuButton` (rather than a guessed
/// shadcn_flutter Popover API) for the dropdown itself, per this codebase's
/// established convention — the button's `itemBuilder` returns one disabled
/// `PopupMenuItem` wrapping fully custom content, which is a standard
/// Flutter trick to get framework-provided positioning/dismiss-on-outside-
/// tap behavior around an arbitrarily-styled panel.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final notifications = context.watch<NotificationsController>();
    final tasks = derivePendingTasks(dataProvider);
    final unread = notifications.unreadCount(tasks.map((t) => t.id));
    final colorScheme = Theme.of(context).colorScheme;

    return material.PopupMenuButton<void>(
      tooltip: '',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 36),
      color: colorScheme.card,
      shape: material.RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.border),
      ),
      itemBuilder: (context) => [
        material.PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 320,
            child: _NotificationDropdown(
              tasks: tasks,
              notifications: notifications,
            ),
          ),
        ),
      ],
      child: _BellIcon(unread: unread),
    );
  }
}

class _BellIcon extends StatelessWidget {
  final int unread;
  const _BellIcon({required this.unread});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: colorScheme.foreground),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationDropdown extends StatelessWidget {
  final List<PendingTask> tasks;
  final NotificationsController notifications;

  const _NotificationDropdown({required this.tasks, required this.notifications});

  // Same icon/color-per-kind mapping as `PendingTasksPanel`, kept in sync
  // deliberately — the bell and the dashboard panel are two views onto the
  // same list, so a task should look the same in both places.
  (IconData, Color) _styleFor(PendingTaskKind kind, ColorScheme colors) {
    switch (kind) {
      case PendingTaskKind.signature:
        return (Icons.draw_outlined, Colors.orange.shade600);
    }
  }

  void _handleTap(BuildContext context, PendingTask task) {
    notifications.markRead(task.id);
    // Closes the popup route first — navigating while it's still on top
    // would leave it stuck open over the new screen.
    Navigator.of(context).pop();
    // Only client-linked tasks have anywhere to go today (the client
    // file screen) — low-stock/inventory tasks have no dedicated screen
    // yet, same gap already flagged on the dashboard's pending tasks
    // panel, so those just get marked read instead of navigating nowhere.
    if (task.clientId != null) {
      context.go('/clients/${task.clientId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Cap the visible list so the dropdown can't grow taller than the
    // viewport on a small window — same reasoning as capping the floating
    // action bar's width earlier, just for height here instead.
    final visible = tasks.take(6).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(AppStrings.notificationsPanelTitle).semiBold(),
          ),
          Container(height: 1, color: colorScheme.border),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(AppStrings.notificationsEmpty).muted(),
            )
          else
            Flexible(
              child: material.ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, i) {
                  final task = visible[i];
                  final (icon, color) = _styleFor(task.kind, colorScheme);
                  final isRead = notifications.isRead(task.id);
                  return material.InkWell(
                    onTap: () => _handleTap(context, task),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, size: 16, color: color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title).small(),
                                Text(task.subtitle).muted(),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(height: 1, color: colorScheme.border),
          material.InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.go('/tasks');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  AppStrings.notificationsSeeAll,
                  style: TextStyle(color: colorScheme.primary),
                ).small(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
