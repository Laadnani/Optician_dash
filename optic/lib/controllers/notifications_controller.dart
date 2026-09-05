import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Tracks which notifications the doctor has already seen — in-memory only
/// (not persisted to shared_preferences), since it resets to "all unread"
/// on a fresh app launch same as the underlying pending tasks it mirrors.
///
/// Deliberately just a read/unread ledger keyed by [PendingTask.id], not a
/// separate notification model — the bell (`NotificationBell`, wired into
/// `AppShell` so it shows on every screen) derives its list straight from
/// `derivePendingTasks(DataProvider)` (see `dashboard_repository.dart`),
/// same source of truth the dashboard's "Needs your attention" panel uses.
/// This controller only adds the one thing that data doesn't have on its
/// own: which of those ids has already been opened/tapped.
class NotificationsController extends ChangeNotifier {
  final Set<String> _readIds = {};

  bool isRead(String id) => _readIds.contains(id);

  void markRead(String id) {
    if (_readIds.add(id)) {
      notifyListeners();
    }
  }

  void markAllRead(Iterable<String> ids) {
    final before = _readIds.length;
    _readIds.addAll(ids);
    if (_readIds.length != before) {
      notifyListeners();
    }
  }

  /// How many of [ids] haven't been marked read yet — what the bell's badge
  /// count shows.
  int unreadCount(Iterable<String> ids) =>
      ids.where((id) => !_readIds.contains(id)).length;
}
