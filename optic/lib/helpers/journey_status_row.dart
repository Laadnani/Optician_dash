import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../data/data_provider.dart';
import '../localization/app_strings.dart';
import 'journey_header.dart';
import 'nav_items.dart';

/// Every journey step downstream of "Client" that actually has a fillable
/// form to jump to. Billing is deliberately left out — invoices are derived
/// automatically from appointments, so there's no "+Add" form for it.
/// Calendar and Communication are excluded too, per request.
const List<NavRoute> kClientJourneyStatusSteps = [
  NavRoute.consultation,
  NavRoute.prescriptions,
  NavRoute.measurements,
  NavRoute.frameSelection,
  NavRoute.lensRecommendation,
  NavRoute.quotes,
  NavRoute.orders,
  NavRoute.laboratory,
  NavRoute.mounting,
  NavRoute.qualityControl,
  NavRoute.finalFitting,
  NavRoute.delivery,
  NavRoute.afterSales,
  NavRoute.repairs,
  NavRoute.warranty,
];

/// Whether this client already has at least one record for [route] — the
/// "green vs orange" check for [ClientJourneyStatusRow].
bool clientHasJourneyData(
  DataProvider dataProvider,
  NavRoute route,
  String clientId,
) {
  switch (route) {
    case NavRoute.calendar:
      return dataProvider.appointments.any((a) => a.clientId == clientId);
    case NavRoute.consultation:
      return dataProvider.consultations.any((c) => c.clientId == clientId);
    case NavRoute.prescriptions:
      return dataProvider.prescriptions.any((p) => p.clientId == clientId);
    case NavRoute.measurements:
      return dataProvider.measurements.any((m) => m.clientId == clientId);
    case NavRoute.frameSelection:
      return dataProvider.frameSelectionSessions.any(
        (s) => s.clientId == clientId,
      );
    case NavRoute.lensRecommendation:
      return dataProvider.lensRecommendations.any(
        (r) => r.clientId == clientId,
      );
    case NavRoute.communication:
      return dataProvider.communicationLogs.any((l) => l.clientId == clientId);
    case NavRoute.quotes:
      return dataProvider.quotes.any((q) => q.clientId == clientId);
    case NavRoute.orders:
      return dataProvider.orders.any((o) => o.clientId == clientId);
    case NavRoute.laboratory:
      return dataProvider.labWorkOrders.any((w) => w.clientId == clientId);
    case NavRoute.mounting:
      return dataProvider.mountingJobs.any((j) => j.clientId == clientId);
    case NavRoute.qualityControl:
      return dataProvider.qualityChecks.any((c) => c.clientId == clientId);
    case NavRoute.finalFitting:
      return dataProvider.finalFittings.any((f) => f.clientId == clientId);
    case NavRoute.delivery:
      return dataProvider.deliveryRecords.any((d) => d.clientId == clientId);
    case NavRoute.afterSales:
      return dataProvider.afterSalesTickets.any((t) => t.clientId == clientId);
    case NavRoute.repairs:
      return dataProvider.repairTickets.any((t) => t.clientId == clientId);
    case NavRoute.warranty:
      return dataProvider.warrantyClaims.any((c) => c.clientId == clientId);
    default:
      return false;
  }
}

/// A modern, minimal linear progress bar for one client's file — one thin
/// rounded segment per journey step still to fill in, filled (brand green)
/// once at least one record exists for that step, a plain muted track
/// while it's still empty. Segments sit edge to edge across the full
/// available width (no horizontal scrolling needed, unlike the old row of
/// circular dots) with a hairline gap between them, capped by an "X of Y
/// steps completed" caption underneath. Tapping a segment still jumps
/// straight to that step's own "+Add" form, pre-scoped to this client (via
/// `extra: {'clientId': ..., 'openAdd': true}`, the same mechanism the
/// sidebar and dashboard quick-actions already use).
class ClientJourneyStatusRow extends StatelessWidget {
  final String clientId;

  const ClientJourneyStatusRow({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final completed = kClientJourneyStatusSteps
        .where(
          (route) => clientHasJourneyData(dataProvider, route, clientId),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final route in kClientJourneyStatusSteps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: _JourneyStepSegment(
                    route: route,
                    complete: clientHasJourneyData(
                      dataProvider,
                      route,
                      clientId,
                    ),
                    onTap: () => context.go(
                      route.path,
                      extra: {'clientId': clientId, 'openAdd': true},
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.clientJourneyStepsCompleted(
            completed,
            kClientJourneyStatusSteps.length,
          ),
        ).muted().small(),
      ],
    );
  }
}

class _JourneyStepSegment extends StatelessWidget {
  final NavRoute route;
  final bool complete;
  final VoidCallback onTap;

  const _JourneyStepSegment({
    required this.route,
    required this.complete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // "Unavailable"/incomplete track — darkened 40% toward black from the
    // theme's own muted color (rather than a fixed gray) so it stays
    // correct across every color family and light/dark mode, per request.
    final incompleteColor = Color.lerp(colorScheme.muted, Colors.black, 0.4)!;
    final color = complete ? Colors.green.shade600 : incompleteColor;
    final label = journeyStepLabel(route);

    return material.Tooltip(
      message: label,
      child: material.InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: material.AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // 60% taller than the original 6px, per request, so the
            // steps read more clearly at a glance.
            height: 9.6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
