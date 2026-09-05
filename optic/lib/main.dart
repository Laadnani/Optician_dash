// main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding, WidgetsBinding;
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'firebase_options.dart';
import 'constants.dart';
import 'controllers/menu_app_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/dashboard_prefs_controller.dart';
import 'controllers/tenant_session.dart';
import 'data/data_provider.dart';
import 'models/client.dart';
import 'helpers/nav_items.dart';
import 'localization/app_strings.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/add_client_screen.dart';
import 'screens/client_file_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/measurements_screen.dart';
import 'screens/frame_inventory_screen.dart';
import 'screens/lens_catalog_screen.dart';
import 'screens/contact_lenses_screen.dart';
import 'screens/communication_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/frame_selection_screen.dart';
import 'screens/lens_recommendation_screen.dart';
import 'screens/accessories_screen.dart';
import 'screens/quotes_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/laboratory_screen.dart';
import 'screens/mounting_screen.dart';
import 'screens/quality_control_screen.dart';
import 'screens/final_fitting_screen.dart';
import 'screens/delivery_screen.dart';
import 'screens/after_sales_screen.dart';
import 'screens/repairs_screen.dart';
import 'screens/warranty_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/purchasing_screen.dart';

void main() async {
  // Firebase has to be initialized before anything below touches
  // firebase_auth/cloud_firestore (DataProvider's future Firestore
  // listeners, an eventual login gate, etc.) — this is the one bit of
  // async setup `main()` needs now that didn't exist before.
  // `WidgetsFlutterBinding.ensureInitialized()` is required whenever
  // `main()` does anything async ahead of `runApp`.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Web's browser-storage persistence already defaults to LOCAL (survives
  // tab refreshes/browser restarts), same as native platforms' own secure
  // storage — but pinning it explicitly here is a safety net against that
  // default ever changing upstream or being session-scoped in some
  // embedding (e.g. an iframe), either of which would otherwise force a
  // sign-in on every reload. `setPersistence` is web-only in firebase_auth
  // — calling it on Android/iOS/desktop throws, hence the `kIsWeb` guard.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  // Single runApp call. MultiProvider has to be the outermost widget so
  // MenuAppController/DataProvider/ThemeController are available to every
  // routed screen (they live above the Router, not inside it) — that's
  // the one thing the doc's flat `runApp(ShadcnApp(...))` example doesn't
  // need to account for, since it has no providers at all.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuAppController()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => NotificationsController()),
        ChangeNotifierProvider(create: (_) => DashboardPrefsController()),
        // Must come before anything that reads it (the auth gate below,
        // eventually DataProvider's Firestore listeners) — registered here
        // so it's available the same way every other controller is.
        ChangeNotifierProvider(create: (_) => TenantSession()),
      ],
      child: const _App(),
    ),
  );
}

/// The actual ShadcnApp root — kept as its own widget (rather than inlined
/// in `main()`) only so it can read ThemeController via Consumer. This is
/// the single `ShadcnApp` in the whole tree.
class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        // Keeps AppStrings' active language in sync with whatever's
        // persisted, every time ThemeController notifies (including a
        // language change from Settings) — since this Consumer rebuilds
        // the whole routed tree below, every screen picks up the new
        // strings on the very next frame without watching anything itself.
        AppStrings.setLanguage(themeController.language.code);
        return ShadcnApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Doc CRM',
          scaling: const AdaptiveScaling(0.85),
          theme: themeController.themeData,
          // Applies the card border/shadow to every `Card` in the app, flips
          // the whole tree to right-to-left when Arabic is the selected
          // language, and drives the two ambient halves of scaling:
          //  - text scaling via `MediaQuery.textScaler`, which every `Text`
          //    widget in the app reads automatically (framework-level, no
          //    per-widget wiring needed).
          //  - icon scaling via an ambient `IconTheme.merge`, which only
          //    reaches icons that don't already pass an explicit `size:`
          //    (most icons here do, and override this — those are scaled
          //    manually at their own call sites instead, e.g. sidebar nav
          //    and KPI cards).
          // `builder` wraps whatever GoRouter renders, so all of this sits
          // above every screen without each one needing to wrap itself.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeController.textScaling),
            ),
            child: IconTheme.merge(
              data: IconThemeData(size: 24 * themeController.iconScaling),
              child: Directionality(
                textDirection: themeController.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: ComponentTheme<CardTheme>(
                  data: themeController.cardTheme,
                  // The button drop-shadow ComponentThemes used to be nested
                  // here too, applying app-wide — moved into `AppShell`
                  // (scoped to just the screen-content area, not the
                  // sidebar/drawer) per the "only on screens, not the
                  // sidebar" follow-up. See `app_shell.dart`.
                  // Auth gate lives right here, swapping in for whatever
                  // GoRouter would otherwise render, rather than as a
                  // separate ShadcnApp/router — this way LoginScreen and
                  // the "resolving your shop" loading state both inherit
                  // the exact same theme/scaling/RTL setup above without a
                  // second app root needing to duplicate any of it.
                  child: Consumer<TenantSession>(
                    builder: (context, tenantSession, _) {
                      // Keep DataProvider's Firestore listeners attached to
                      // whichever tenant TenantSession currently resolves to
                      // — attach on sign-in/tenant-resolution, detach on
                      // sign-out. Deferred to a post-frame callback because
                      // attachTenant()/detachTenant() call notifyListeners()
                      // synchronously, which isn't safe to trigger from
                      // inside this build() call.
                      final dataProvider = context.read<DataProvider>();
                      final targetTenantId =
                          tenantSession.isReady ? tenantSession.tenantId : null;
                      if (dataProvider.attachedTenantId != targetTenantId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (targetTenantId == null) {
                            dataProvider.detachTenant();
                          } else {
                            dataProvider.attachTenant(targetTenantId);
                          }
                        });
                      }
                      // Before the very first authStateChanges() event
                      // arrives, `user` being null doesn't yet mean
                      // "signed out" — an already-logged-in device is
                      // about to come back signed in automatically
                      // (Firebase persists sessions by default). Showing
                      // a bare spinner here instead of LoginScreen is
                      // what makes that reconnect actually seamless,
                      // rather than flashing the login form for a moment
                      // on every cold start.
                      if (!tenantSession.hasCheckedInitialAuth) {
                        return const Center(
                          child: material.CircularProgressIndicator(),
                        );
                      }
                      if (tenantSession.user == null) {
                        return const LoginScreen();
                      }
                      if (tenantSession.isResolvingTenant) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const material.CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(AppStrings.authResolvingWorkspace).muted(),
                            ],
                          ),
                        );
                      }
                      return child!;
                    },
                  ),
                ),
              ),
            ),
          ),
          routerConfig: GoRouter(
            initialLocation: NavRoute.dashboard.path,
            // Every route below uses `pageBuilder: ... => NoTransitionPage(...)`
            // instead of the default `builder:`. Each screen builds its own
            // `AppShell` (sidebar + top bar) rather than sharing one via a
            // ShellRoute, so every sidebar click is a full page push/replace
            // — with the default `MaterialPage`/`CupertinoPage` transition,
            // that's a few hundred ms of slide/fade animation on *every*
            // click, which read as sluggish "latency" for what should feel
            // like an instant tab switch. `NoTransitionPage` keeps the route
            // push (so back/forward, deep links, etc. all still work) but
            // skips the transition animation entirely.
            routes: [
              GoRoute(
                path: NavRoute.dashboard.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const DashboardScreen()),
              ),
              GoRoute(
                path: NavRoute.billing.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const BillingScreen()),
              ),
              GoRoute(
                path: NavRoute.clients.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const ClientsScreen()),
                routes: [
                  // Static "new" route registered before the ":id" param
                  // route below so it isn't swallowed as a literal client
                  // id — GoRouter matches static segments first regardless
                  // of order, but keeping it above documents the intent.
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) => NoTransitionPage(child: const AddClientScreen()),
                  ),
                  // Nested under /clients so the client file inherits the
                  // list route's place in the stack — /clients/:id.
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => NoTransitionPage(
                      child: ClientFileScreen(
                        clientId: state.pathParameters['id']!,
                      ),
                    ),
                    routes: [
                      // /clients/:id/edit — same AddClientScreen form,
                      // pre-filled and in "update" mode (see
                      // AddClientScreen.editClient). Reachable from the
                      // redesigned client file header's "[Edit]" action.
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          Client? client;
                          for (final p in context.read<DataProvider>().clients) {
                            if (p.id == id) {
                              client = p;
                              break;
                            }
                          }
                          return NoTransitionPage(
                            child: AddClientScreen(editClient: client),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: NavRoute.calendar.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const CalendarScreen()),
              ),
              GoRoute(
                path: NavRoute.tasks.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const TasksScreen()),
              ),
              GoRoute(
                path: NavRoute.settings.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const SettingsScreen()),
              ),
              // --- Optical-retail architecture spec: placeholder --------
              // destinations for modules not built yet — each swaps to a
              // real screen (data + metrics UI) one at a time without any
              // further routing changes needed here.
              GoRoute(
                path: NavRoute.prescriptions.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const PrescriptionsScreen()),
              ),
              GoRoute(
                path: NavRoute.measurements.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const MeasurementsScreen()),
              ),
              GoRoute(
                path: NavRoute.communication.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const CommunicationScreen()),
              ),
              GoRoute(
                path: NavRoute.consultation.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const ConsultationScreen()),
              ),
              GoRoute(
                path: NavRoute.frameSelection.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const FrameSelectionScreen()),
              ),
              GoRoute(
                path: NavRoute.lensRecommendation.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const LensRecommendationScreen()),
              ),
              GoRoute(
                path: NavRoute.frameInventory.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const FrameInventoryScreen()),
              ),
              GoRoute(
                path: NavRoute.lensCatalog.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const LensCatalogScreen()),
              ),
              GoRoute(
                path: NavRoute.contactLenses.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const ContactLensesScreen()),
              ),
              GoRoute(
                path: NavRoute.accessories.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const AccessoriesScreen()),
              ),
              GoRoute(
                path: NavRoute.quotes.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const QuotesScreen()),
              ),
              GoRoute(
                path: NavRoute.orders.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const OrdersScreen()),
              ),
              GoRoute(
                path: NavRoute.laboratory.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const LaboratoryScreen()),
              ),
              GoRoute(
                path: NavRoute.mounting.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const MountingScreen()),
              ),
              GoRoute(
                path: NavRoute.qualityControl.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const QualityControlScreen()),
              ),
              GoRoute(
                path: NavRoute.finalFitting.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const FinalFittingScreen()),
              ),
              GoRoute(
                path: NavRoute.delivery.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const DeliveryScreen()),
              ),
              GoRoute(
                path: NavRoute.afterSales.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const AfterSalesScreen()),
              ),
              GoRoute(
                path: NavRoute.repairs.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const RepairsScreen()),
              ),
              GoRoute(
                path: NavRoute.warranty.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const WarrantyScreen()),
              ),
              GoRoute(
                path: NavRoute.suppliers.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const SuppliersScreen()),
              ),
              GoRoute(
                path: NavRoute.purchasing.path,
                pageBuilder: (context, state) => NoTransitionPage(child: const PurchasingScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}
