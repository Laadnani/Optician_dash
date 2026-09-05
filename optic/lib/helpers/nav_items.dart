import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:optic/widgets/sidebar.dart';
import 'package:optic/localization/app_strings.dart';

/// Stable routing/selection identity for each nav destination — separate
/// from its *display* label, so selection/navigation keeps working once
/// labels come from a language file (a translated label is a different
/// string per locale; this enum value never changes).
///
/// The 21 values from [prescriptions] through [purchasing] are placeholder
/// destinations added for the optical-retail architecture spec's remaining
/// modules — each currently renders [PlaceholderScreen] via
/// `buildAppNavItems`'s grouped sections; real screens/data/metrics land on
/// top of these one module at a time without any further routing changes.
enum NavRoute {
  dashboard,
  billing,
  clients,
  calendar,
  tasks,
  settings,
  // --- Clients group (new) ---
  prescriptions,
  measurements,
  communication,
  // --- Optical Consultation group ---
  consultation,
  frameSelection,
  lensRecommendation,
  // --- Products & Inventory group ---
  frameInventory,
  lensCatalog,
  contactLenses,
  accessories,
  // --- Sales group ---
  quotes,
  orders,
  // --- Production group ---
  laboratory,
  mounting,
  qualityControl,
  // --- Client Delivery group ---
  finalFitting,
  delivery,
  afterSales,
  repairs,
  warranty,
  // --- Procurement group ---
  suppliers,
  purchasing,
}

/// The URL path each route maps to. Single source of truth for both the
/// GoRouter config (`routing/app_router.dart`) and anything that needs to
/// navigate there.
extension NavRoutePath on NavRoute {
  String get path {
    switch (this) {
      case NavRoute.dashboard:
        return '/';
      case NavRoute.billing:
        return '/billing';
      case NavRoute.clients:
        return '/clients';
      case NavRoute.calendar:
        return '/calendar';
      case NavRoute.tasks:
        return '/tasks';
      case NavRoute.settings:
        return '/settings';
      case NavRoute.prescriptions:
        return '/prescriptions';
      case NavRoute.measurements:
        return '/measurements';
      case NavRoute.communication:
        return '/communication';
      case NavRoute.consultation:
        return '/consultations';
      case NavRoute.frameSelection:
        return '/frame-selection';
      case NavRoute.lensRecommendation:
        return '/lens-recommendation';
      case NavRoute.frameInventory:
        return '/frames';
      case NavRoute.lensCatalog:
        return '/lenses';
      case NavRoute.contactLenses:
        return '/contact-lenses';
      case NavRoute.accessories:
        return '/accessories';
      case NavRoute.quotes:
        return '/quotes';
      case NavRoute.orders:
        return '/orders';
      case NavRoute.laboratory:
        return '/laboratory';
      case NavRoute.mounting:
        return '/mounting';
      case NavRoute.qualityControl:
        return '/quality-control';
      case NavRoute.finalFitting:
        return '/final-fitting';
      case NavRoute.delivery:
        return '/delivery';
      case NavRoute.afterSales:
        return '/after-sales';
      case NavRoute.repairs:
        return '/repairs';
      case NavRoute.warranty:
        return '/warranty';
      case NavRoute.suppliers:
        return '/suppliers';
      case NavRoute.purchasing:
        return '/purchasing';
    }
  }
}

/// One shared nav list, used by both the desktop sidebar and the
/// mobile/tablet overlay drawer, on every screen. [currentRoute] marks
/// which entry is "selected"; tapping any other entry navigates there via
/// GoRouter.
///
/// Dashboard and Calendar sit ungrouped at the top (daily-use, highest
/// traffic — no group heading needed to find them). Everything else is
/// grouped into the 8 modules from the optical-retail architecture spec's
/// own tree (Clients / Optical Consultation / Products & Inventory /
/// Sales / Production / Client Delivery / Procurement / Management), with
/// already-built screens (Clients, Billing, Settings) living in their
/// spec-mapped section alongside the new placeholder destinations rather
/// than a separate "existing vs. new" split.
List<SidebarEntry> buildAppNavItems(
  BuildContext context,
  NavRoute currentRoute,
) {
  void goTo(NavRoute route) {
    if (route == currentRoute) return; // already here
    // `context` here is captured once per `buildAppNavItems` call and
    // closed over by every `DrawerItem.onTap` built below. Since each
    // screen mounts its own fresh `AppShell`, that context's widget is torn
    // down and replaced on every navigation — if a tap's gesture resolves
    // against a closure built from an already-deactivated context (seen in
    // practice right after a hot restart, where the framework can still be
    // settling the previous element tree when a queued tap fires), calling
    // `context.go(...)` throws "Looking up a deactivated widget's ancestor
    // is unsafe." This guard makes that a silent no-op instead of a crash.
    if (!context.mounted) return;
    context.go(route.path);
  }

  DrawerItem item(NavRoute route, String label, IconData icon) => DrawerItem(
    label: label,
    icon: icon,
    selected: currentRoute == route,
    onTap: () => goTo(route),
  );

  return [
    item(NavRoute.dashboard, AppStrings.navDashboard, Icons.dashboard_outlined),
    item(NavRoute.tasks, AppStrings.navTasks, Icons.badge_outlined),
    item(
      NavRoute.calendar,
      AppStrings.navCalendar,
      Icons.calendar_month_outlined,
    ),

    // --- 1. Clients ---------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionClients),
    item(NavRoute.clients, AppStrings.navClients, Icons.people_outline),
    item(
      NavRoute.prescriptions,
      AppStrings.navPrescriptions,
      Icons.assignment_outlined,
    ),
    item(
      NavRoute.measurements,
      AppStrings.navMeasurements,
      Icons.straighten_outlined,
    ),
    item(
      NavRoute.communication,
      AppStrings.navCommunication,
      Icons.forum_outlined,
    ),

    // --- 2. Optical Consultation -----------------------------------------
    DrawerSectionHeader(AppStrings.navSectionOpticalConsultation),
    item(
      NavRoute.consultation,
      AppStrings.navConsultation,
      Icons.psychology_outlined,
    ),
    item(
      NavRoute.frameSelection,
      AppStrings.navFrameSelection,
      Icons.camera_alt_outlined,
    ),
    item(
      NavRoute.lensRecommendation,
      AppStrings.navLensRecommendation,
      Icons.medical_services_outlined,
    ),

    // --- 3. Products & Inventory -------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionProductsInventory),
    item(
      NavRoute.frameInventory,
      AppStrings.navFrameInventory,
      Icons.inventory_2_outlined,
    ),
    item(
      NavRoute.lensCatalog,
      AppStrings.navLensCatalog,
      Icons.blur_on_outlined,
    ),
    item(
      NavRoute.contactLenses,
      AppStrings.navContactLenses,
      Icons.visibility_outlined,
    ),
    item(
      NavRoute.accessories,
      AppStrings.navAccessories,
      Icons.shopping_bag_outlined,
    ),

    // --- 4. Sales -----------------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionSales),
    item(NavRoute.quotes, AppStrings.navQuotes, Icons.request_quote_outlined),
    item(NavRoute.orders, AppStrings.navOrders, Icons.shopping_cart_outlined),
    item(NavRoute.billing, AppStrings.navBilling, Icons.receipt_long_outlined),

    // --- 5. Production --------------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionProduction),
    item(NavRoute.laboratory, AppStrings.navLaboratory, Icons.science_outlined),
    item(NavRoute.mounting, AppStrings.navMounting, Icons.build_outlined),
    item(
      NavRoute.qualityControl,
      AppStrings.navQualityControl,
      Icons.verified_outlined,
    ),

    // --- 6. Client Delivery -----------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionClientDelivery),
    item(NavRoute.finalFitting, AppStrings.navFinalFitting, Icons.tune_outlined),
    item(
      NavRoute.delivery,
      AppStrings.navDelivery,
      Icons.local_shipping_outlined,
    ),
    item(
      NavRoute.afterSales,
      AppStrings.navAfterSales,
      Icons.support_agent_outlined,
    ),
    item(
      NavRoute.repairs,
      AppStrings.navRepairs,
      Icons.build_circle_outlined,
    ),
    item(
      NavRoute.warranty,
      AppStrings.navWarranty,
      Icons.verified_user_outlined,
    ),

    // --- 7. Procurement -----------------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionProcurement),
    item(NavRoute.suppliers, AppStrings.navSuppliers, Icons.storefront_outlined),
    item(
      NavRoute.purchasing,
      AppStrings.navPurchasing,
      Icons.shopping_cart_checkout_outlined,
    ),

    // --- 8. Management --------------------------------------------------------
    DrawerSectionHeader(AppStrings.navSectionManagement),
    item(NavRoute.settings, AppStrings.navSettings, Icons.settings_outlined),
  ];
}
