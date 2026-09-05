import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'nav_items.dart';
import '../localization/app_strings.dart';

/// The client lifecycle, in order — every screen that holds a record tied
/// to one specific client, from intake through after-sales. Deliberately
/// excludes the non-client modules (frame/lens/contact-lens/accessories
/// catalogs, suppliers, purchasing): those are stock/vendor data that
/// don't belong to any one client's journey.
///
/// This is the single source of truth for both the step order and which
/// screens count as "part of the journey" — [JourneyHeader] just renders
/// whatever's here, so adding/reordering a step only means editing this
/// list.
const List<NavRoute> kClientJourneySteps = [
  NavRoute.clients,
  NavRoute.calendar,
  NavRoute.consultation,
  NavRoute.prescriptions,
  NavRoute.measurements,
  NavRoute.frameSelection,
  NavRoute.lensRecommendation,
  NavRoute.communication,
  NavRoute.quotes,
  NavRoute.orders,
  NavRoute.laboratory,
  NavRoute.mounting,
  NavRoute.qualityControl,
  NavRoute.finalFitting,
  NavRoute.delivery,
  NavRoute.billing,
  NavRoute.afterSales,
  NavRoute.repairs,
  NavRoute.warranty,
];

/// Reuses the exact same labels the sidebar already shows for these routes
/// (already localized EN/FR/AR) instead of introducing a second, easy-to-
/// drift-out-of-sync set of strings for the same destinations.
String journeyStepLabel(NavRoute route) {
  switch (route) {
    case NavRoute.clients:
      return AppStrings.navClients;
    case NavRoute.calendar:
      return AppStrings.navCalendar;
    case NavRoute.consultation:
      return AppStrings.navConsultation;
    case NavRoute.prescriptions:
      return AppStrings.navPrescriptions;
    case NavRoute.measurements:
      return AppStrings.navMeasurements;
    case NavRoute.frameSelection:
      return AppStrings.navFrameSelection;
    case NavRoute.lensRecommendation:
      return AppStrings.navLensRecommendation;
    case NavRoute.communication:
      return AppStrings.navCommunication;
    case NavRoute.quotes:
      return AppStrings.navQuotes;
    case NavRoute.orders:
      return AppStrings.navOrders;
    case NavRoute.laboratory:
      return AppStrings.navLaboratory;
    case NavRoute.mounting:
      return AppStrings.navMounting;
    case NavRoute.qualityControl:
      return AppStrings.navQualityControl;
    case NavRoute.finalFitting:
      return AppStrings.navFinalFitting;
    case NavRoute.delivery:
      return AppStrings.navDelivery;
    case NavRoute.billing:
      return AppStrings.navBilling;
    case NavRoute.afterSales:
      return AppStrings.navAfterSales;
    case NavRoute.repairs:
      return AppStrings.navRepairs;
    case NavRoute.warranty:
      return AppStrings.navWarranty;
    default:
      return route.name;
  }
}

/// A horizontally-scrollable "you are here" strip for the client journey —
/// every step from [kClientJourneySteps], the current one highlighted and
/// non-interactive, every other one a tappable shortcut straight to that
/// step's own fill-in form — not just its browsing screen. Tapping "Client"
/// opens the client intake form (`/clients/new`); tapping any other step
/// navigates to that module and auto-opens its "+ Add" dialog via the
/// `extra: {'openAdd': true}` flag those screens already know how to
/// consume. It doesn't carry the current client along, same as clicking the
/// item in the sidebar would.
///
/// Drop this in as the very first child of a screen's body [Column], right
/// above its own title row. Set [closesDialog] to true when this header is
/// rendered inside a modal dialog (e.g. the shared "+Add" popup) so a tap
/// dismisses that dialog before navigating to the next form.
class JourneyHeader extends StatelessWidget {
  final NavRoute current;
  final bool closesDialog;

  const JourneyHeader({
    super.key,
    required this.current,
    this.closesDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < kClientJourneySteps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.mutedForeground,
                ),
              ),
            _JourneyStepChip(
              route: kClientJourneySteps[i],
              isCurrent: kClientJourneySteps[i] == current,
              closesDialog: closesDialog,
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the actual fill-in form for [route] instead of just its list
/// screen. The client step is a dedicated page (`/clients/new`); every
/// other step is its module screen with `extra: {'openAdd': true}`, which
/// each of those screens' `initState` already watches for to auto-launch
/// its own "+ Add" dialog.
void _openJourneyForm(BuildContext context, NavRoute route) {
  if (route == NavRoute.clients) {
    context.go('/clients/new');
    return;
  }
  context.go(route.path, extra: const {'openAdd': true});
}

class _JourneyStepChip extends StatelessWidget {
  final NavRoute route;
  final bool isCurrent;
  final bool closesDialog;

  const _JourneyStepChip({
    required this.route,
    required this.isCurrent,
    this.closesDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = journeyStepLabel(route);

    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primary, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Button.outline(
      onPressed: () {
        if (closesDialog) {
          Navigator.of(context).pop();
        }
        _openJourneyForm(context, route);
      },
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
