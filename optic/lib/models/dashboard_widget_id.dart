import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

/// One toggleable section of the dashboard. Declaration order here is the
/// canonical render order — [DashboardScreen] just walks
/// [DashboardPrefsController.enabledWidgets] and renders whichever of these
/// are turned on, in this order; the Settings → Dashboard tab lets the
/// user flip any of them on/off (see `dashboard_prefs_controller.dart`).
///
/// Every value's name is persisted to shared_preferences verbatim, so
/// renaming a value here would silently reset that widget to its default
/// on next launch — add new ones at the end and treat existing names as
/// stable identifiers.
///
/// Replaced wholesale for the Aug 2026 "minimalist operational center"
/// redesign — the old 13-widget catalog (monthlyRevenue, todaysSnapshot,
/// calendarAppointments, clientsOverview, prescriptionAlerts,
/// ordersPipeline, quotesPipeline, afterSalesOverview, qualityOverview,
/// recentClients, etc.) is gone. The redesign's whole point is fewer
/// widgets with a clearer role each: one always-on KPI row (Clients /
/// Appointments / Sales / Orders, see `dashboard_widgets.dart`'s
/// `DashboardKpiSummaryRow`) plus these four toggleable sections. Existing
/// installs simply fall back to "every new id enabled" the same way a
/// fresh install always has (see `DashboardPrefsController`'s "unknown
/// names are dropped" handling) — a one-time reset, not a crash.
enum DashboardWidgetId {
  attention,
  tasksAndAppointments,
  salesAndActivity,
  inventoryAndActions,
}

/// Display metadata for the Settings → Dashboard toggle list. Kept out of
/// the enum itself since `AppStrings` getters aren't compile-time
/// constants (can't live in a `const` context), and translated
/// label/description text belongs in one place either way.
extension DashboardWidgetIdInfo on DashboardWidgetId {
  String get label {
    switch (this) {
      case DashboardWidgetId.attention:
        return AppStrings.dashWidgetAttention;
      case DashboardWidgetId.tasksAndAppointments:
        return AppStrings.dashWidgetTasksAndAppointments;
      case DashboardWidgetId.salesAndActivity:
        return AppStrings.dashWidgetSalesAndActivity;
      case DashboardWidgetId.inventoryAndActions:
        return AppStrings.dashWidgetInventoryAndActions;
    }
  }

  String get description {
    switch (this) {
      case DashboardWidgetId.attention:
        return AppStrings.dashWidgetAttentionDesc;
      case DashboardWidgetId.tasksAndAppointments:
        return AppStrings.dashWidgetTasksAndAppointmentsDesc;
      case DashboardWidgetId.salesAndActivity:
        return AppStrings.dashWidgetSalesAndActivityDesc;
      case DashboardWidgetId.inventoryAndActions:
        return AppStrings.dashWidgetInventoryAndActionsDesc;
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardWidgetId.attention:
        return Icons.error_outline;
      case DashboardWidgetId.tasksAndAppointments:
        return Icons.checklist_outlined;
      case DashboardWidgetId.salesAndActivity:
        return Icons.show_chart_outlined;
      case DashboardWidgetId.inventoryAndActions:
        return Icons.inventory_2_outlined;
    }
  }
}
