import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optic/constants.dart';
import 'package:optic/models/dashboard_widget_id.dart';

/// Which dashboard widgets are currently switched on, persisted on-device
/// via shared_preferences — same "simple, dedicated controller" shape as
/// [ThemeController], just for a single `Set<DashboardWidgetId>` instead of
/// a full theme snapshot.
///
/// Every [DashboardWidgetId] is on by default (a fresh install shows the
/// full dashboard); Settings → Dashboard is where a doctor/optician trims
/// it down to just what they check daily.
class DashboardPrefsController extends ChangeNotifier {
  Set<DashboardWidgetId> _enabled = DashboardWidgetId.values.toSet();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Render order for [DashboardScreen] — canonical enum order, filtered
  /// down to whatever's currently enabled.
  List<DashboardWidgetId> get enabledWidgets =>
      DashboardWidgetId.values.where(_enabled.contains).toList();

  bool isEnabled(DashboardWidgetId id) => _enabled.contains(id);

  DashboardPrefsController() {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(DashboardPrefsKeys.enabledWidgets);
    if (raw != null) {
      // Unknown names (e.g. from a future version, or a stale one after a
      // widget was renamed) are silently dropped rather than crashing.
      final byName = {for (final v in DashboardWidgetId.values) v.name: v};
      _enabled = raw
          .map((name) => byName[name])
          .whereType<DashboardWidgetId>()
          .toSet();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      DashboardPrefsKeys.enabledWidgets,
      _enabled.map((v) => v.name).toList(),
    );
  }

  void toggle(DashboardWidgetId id) {
    if (_enabled.contains(id)) {
      _enabled.remove(id);
    } else {
      _enabled.add(id);
    }
    notifyListeners();
    _persist();
  }

  void setEnabled(DashboardWidgetId id, bool value) {
    if (value == _enabled.contains(id)) return;
    toggle(id);
  }
}
