import 'package:optic/data/data_provider.dart';
import '../localization/app_strings.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/eye_exam.dart';
import '../models/billing.dart';
import '../models/payments.dart';
import '../models/insurance.dart';
import '../models/document.dart';
import '../models/digital_signature.dart';
import '../models/prescription.dart';
import '../models/measurement.dart';
import '../models/contact_lens.dart';
import '../models/client_timeline_event.dart';
import '../models/optical_consultation.dart';
import '../models/frame_selection.dart';
import '../models/lens_recommendation.dart';
import '../models/communication_log.dart';
import '../models/quote.dart';
import '../models/order.dart';
import '../models/lab_work_order.dart';
import '../models/mounting_job.dart';
import '../models/quality_check.dart';
import '../models/final_fitting.dart';
import '../models/delivery_record.dart';
import '../models/after_sales_ticket.dart';
import '../models/repair_ticket.dart';
import '../models/warranty_claim.dart';

/// Everything a single client's file needs, keyed off `Client.id`. Mirrors
/// `DashboardRepository`'s shape: `ClientsScreen`/`ClientFileScreen` only
/// ever talk to this interface — swap `DataProvider`'s mock lists for a real
/// backend later and neither screen needs to change.
///
/// Trimmed down as part of the clinical → optical-retail pivot: fetch
/// methods for the deleted clinical-only models (medical history,
/// allergies, SOAP notes, diagnoses, imaging orders, referrals, vital
/// signs, lab orders, DICOM files, medication prescriptions) are gone.
abstract class ClientRepository {
  Future<List<Client>> fetchClients();
  Future<Client?> fetchClient(String clientId);

  Future<List<Appointment>> fetchAppointments(String clientId);
  Future<List<EyeExam>> fetchEyeExams(String clientId);
  Future<List<Invoice>> fetchInvoices(String clientId);
  Future<List<Payment>> fetchPayments(String clientId);
  Future<List<Insurance>> fetchInsurances(String clientId);
  Future<List<DocumentRecord>> fetchDocuments(String clientId);
  Future<List<DigitalSignature>> fetchSignatures(String clientId);

  /// Module 1's "First visit / Last visit / Total purchases / Lifetime
  /// value" — computed on demand rather than stored on [Client] (see
  /// [deriveClientMetrics]).
  Future<ClientMetrics> fetchClientMetrics(String clientId);

  // --- Modules 2/3/6: client-scoped optical records -----------------------
  // Frame/Lens/ContactLensProduct (modules 4/5/6's catalogs) are store-wide,
  // not per-client, so they're read straight off `DataProvider` by their
  // own screens instead of living here.
  Future<List<Prescription>> fetchPrescriptions(String clientId);
  Future<List<Measurement>> fetchMeasurements(String clientId);
  Future<List<ContactLensPrescription>> fetchContactLensPrescriptions(
    String clientId,
  );

  /// The CRM flow diagram's "Client Timeline" node — every client-linked
  /// record across every module, merged into one chronological feed (see
  /// [deriveClientTimeline]).
  Future<List<ClientTimelineEvent>> fetchClientTimeline(String clientId);
}

/// First/last visit + purchase totals for one client — the spec's module 1
/// fields that are derived rather than stored (see [Client]'s doc comment).
class ClientMetrics {
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  /// Count of this client's paid appointments — the closest thing to
  /// "total purchases" until a real Order entity (module 9) exists.
  final int totalPurchases;

  /// Sum of `Appointment.price` across this client's paid appointments, in
  /// MAD — same revenue source `BillingScreen` already uses, so a client's
  /// LTV here always reconciles with what the billing screen counted.
  final double lifetimeValue;

  const ClientMetrics({
    required this.firstVisit,
    required this.lastVisit,
    required this.totalPurchases,
    required this.lifetimeValue,
  });
}

/// Derives [ClientMetrics] straight from `DataProvider.appointments` —
/// no separate "purchase history" table exists (or needs to) while Orders
/// (module 9) aren't built yet. Pulled out as a synchronous top-level
/// function (same pattern as `derivePendingTasks`/`deriveWeeklyAppointmentRevenue`)
/// so it's reusable from both `ProviderClientRepository` and anywhere else
/// that has a `DataProvider` handy without going through a `Future`.
ClientMetrics deriveClientMetrics(DataProvider dataProvider, String clientId) {
  final appointments = dataProvider.appointments
      .where((a) => a.clientId == clientId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (appointments.isEmpty) {
    return const ClientMetrics(
      firstVisit: null,
      lastVisit: null,
      totalPurchases: 0,
      lifetimeValue: 0,
    );
  }

  final paid = appointments.where((a) => a.paymentStatus == 'paid');

  return ClientMetrics(
    firstVisit: appointments.first.date,
    lastVisit: appointments.last.date,
    totalPurchases: paid.length,
    lifetimeValue: paid.fold<double>(0, (sum, a) => sum + a.price),
  );
}

/// Turns a raw camelCase enum value (`'inProgress'`, `'visionIssue'`) into a
/// human-readable label (`'In Progress'`, `'Vision Issue'`) for timeline
/// subtitles. Every model's status/type enum already has its own fully
/// localized label helper in its screen file — duplicating all ~15 of those
/// here just for the timeline isn't worth the added AppStrings surface
/// area, so this is a readable, unlocalized fallback instead.
String _titleCase(String value) {
  if (value.isEmpty) return value;
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Merges every client-linked record across every module into one
/// chronological feed — the CRM flow diagram's "Client Timeline" node,
/// which was the diagram's biggest gap before this: the client file never
/// showed a client's Orders, Repairs, Complaints, or Warranty claims in one
/// place even though every one of those records already carries
/// `clientId`. Pulled out as a synchronous top-level function (same
/// pattern as [deriveClientMetrics]) so it's reusable from
/// `ProviderClientRepository` without going through a `Future`. Newest
/// first, matching every other tab in the client file.
List<ClientTimelineEvent> deriveClientTimeline(
  DataProvider dataProvider,
  String clientId,
) {
  final events = <ClientTimelineEvent>[];

  for (final a in dataProvider.appointments.where((a) => a.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${a.id}',
      title: AppStrings.clientFileTabAppointments,
      subtitle: '${a.reason} — ${_titleCase(a.status)}',
      kind: ClientTimelineEventKind.appointment,
      sourceId: a.id,
      date: a.date,
    ));
  }

  for (final c in dataProvider.consultations.where((c) => c.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${c.id}',
      title: AppStrings.navConsultation,
      subtitle: c.visualNeeds.isEmpty ? _titleCase(c.screenUsage) : c.visualNeeds,
      kind: ClientTimelineEventKind.consultation,
      sourceId: c.id,
      date: c.date,
    ));
  }

  for (final e in dataProvider.eyeExams.where((e) => e.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${e.id}',
      title: AppStrings.clientFileTabExams,
      subtitle: e.notes.isEmpty
          ? '${AppStrings.prescriptionColRightEye} ${e.visualAcuityOD} · ${AppStrings.prescriptionColLeftEye} ${e.visualAcuityOS}'
          : e.notes,
      kind: ClientTimelineEventKind.eyeExam,
      sourceId: e.id,
      date: e.examDate,
    ));
  }

  for (final p in dataProvider.prescriptions.where((p) => p.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${p.id}',
      title: AppStrings.navPrescriptions,
      subtitle: _titleCase(p.type),
      kind: ClientTimelineEventKind.prescription,
      sourceId: p.id,
      date: p.date,
    ));
  }

  for (final m in dataProvider.measurements.where((m) => m.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${m.id}',
      title: AppStrings.navMeasurements,
      subtitle: _titleCase(m.method),
      kind: ClientTimelineEventKind.measurement,
      sourceId: m.id,
      date: m.date,
    ));
  }

  for (final f in dataProvider.frameSelectionSessions.where((f) => f.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${f.id}',
      title: AppStrings.navFrameSelection,
      subtitle: _titleCase(f.method),
      kind: ClientTimelineEventKind.frameSelection,
      sourceId: f.id,
      date: f.date,
    ));
  }

  for (final r in dataProvider.lensRecommendations.where((r) => r.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${r.id}',
      title: AppStrings.navLensRecommendation,
      subtitle: r.recommendedLensType,
      kind: ClientTimelineEventKind.lensRecommendation,
      sourceId: r.id,
      date: r.date,
    ));
  }

  for (final c in dataProvider.communicationLogs.where((c) => c.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${c.id}',
      title: AppStrings.navCommunication,
      subtitle: c.subject.isEmpty ? _titleCase(c.channel) : c.subject,
      kind: ClientTimelineEventKind.communication,
      sourceId: c.id,
      date: c.date,
    ));
  }

  for (final q in dataProvider.quotes.where((q) => q.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${q.id}',
      title: AppStrings.navQuotes,
      subtitle: '${q.description} — ${_titleCase(q.status)}',
      kind: ClientTimelineEventKind.quote,
      sourceId: q.id,
      date: q.date,
    ));
  }

  for (final o in dataProvider.orders.where((o) => o.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${o.id}',
      title: AppStrings.navOrders,
      subtitle: '${o.description} — ${_titleCase(o.status)}',
      kind: ClientTimelineEventKind.order,
      sourceId: o.id,
      date: o.date,
    ));
  }

  // Payment only carries `invoiceId`, not `clientId` — join through this
  // client's invoices first (same join `fetchPayments` above already
  // does). The diagram's "Client Timeline" box explicitly lists
  // "Payments" as its own line alongside Invoice/Orders, so these get
  // their own timeline entries rather than being folded into Invoice's.
  final clientInvoiceIds = dataProvider.invoices
      .where((i) => i.clientId == clientId)
      .map((i) => i.id)
      .toSet();
  for (final p in dataProvider.payments.where((p) => clientInvoiceIds.contains(p.invoiceId))) {
    events.add(ClientTimelineEvent(
      id: 'tl_${p.id}',
      title: AppStrings.sectionPayments,
      subtitle: '${p.amount.toStringAsFixed(0)} MAD — ${_titleCase(p.method)}',
      kind: ClientTimelineEventKind.payment,
      sourceId: p.id,
      date: p.date,
    ));
  }

  for (final l in dataProvider.labWorkOrders.where((l) => l.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${l.id}',
      title: AppStrings.navLaboratory,
      subtitle: '${_titleCase(l.taskType)} — ${_titleCase(l.status)}',
      kind: ClientTimelineEventKind.labWorkOrder,
      sourceId: l.id,
      date: l.date,
    ));
  }

  for (final j in dataProvider.mountingJobs.where((j) => j.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${j.id}',
      title: AppStrings.navMounting,
      subtitle: _titleCase(j.status),
      kind: ClientTimelineEventKind.mountingJob,
      sourceId: j.id,
      date: j.date,
    ));
  }

  for (final c in dataProvider.qualityChecks.where((c) => c.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${c.id}',
      title: AppStrings.navQualityControl,
      subtitle: '${_titleCase(c.checkType)} — ${_titleCase(c.result)}',
      kind: ClientTimelineEventKind.qualityCheck,
      sourceId: c.id,
      date: c.date,
    ));
  }

  for (final f in dataProvider.finalFittings.where((f) => f.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${f.id}',
      title: AppStrings.navFinalFitting,
      subtitle: _titleCase(f.adjustmentType),
      kind: ClientTimelineEventKind.finalFitting,
      sourceId: f.id,
      date: f.date,
    ));
  }

  for (final i in dataProvider.invoices.where((i) => i.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${i.id}',
      title: AppStrings.sectionInvoices,
      subtitle: '${i.amount.toStringAsFixed(0)} MAD — ${_titleCase(i.status)}',
      kind: ClientTimelineEventKind.invoice,
      sourceId: i.id,
      date: i.date,
    ));
  }

  for (final d in dataProvider.deliveryRecords.where((d) => d.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${d.id}',
      title: AppStrings.navDelivery,
      subtitle: '${_titleCase(d.method)} — ${_titleCase(d.status)}',
      kind: ClientTimelineEventKind.delivery,
      sourceId: d.id,
      date: d.date,
    ));
  }

  for (final t in dataProvider.afterSalesTickets.where((t) => t.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${t.id}',
      title: AppStrings.navAfterSales,
      subtitle: '${_titleCase(t.issueType)} — ${_titleCase(t.status)}',
      kind: ClientTimelineEventKind.afterSales,
      sourceId: t.id,
      date: t.date,
    ));
  }

  for (final t in dataProvider.repairTickets.where((t) => t.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${t.id}',
      title: AppStrings.navRepairs,
      subtitle: '${_titleCase(t.itemType)} — ${_titleCase(t.status)}',
      kind: ClientTimelineEventKind.repair,
      sourceId: t.id,
      date: t.date,
    ));
  }

  for (final c in dataProvider.warrantyClaims.where((c) => c.clientId == clientId)) {
    events.add(ClientTimelineEvent(
      id: 'tl_${c.id}',
      title: AppStrings.navWarranty,
      subtitle: '${_titleCase(c.itemType)} — ${_titleCase(c.status)}',
      kind: ClientTimelineEventKind.warranty,
      sourceId: c.id,
      date: c.date,
    ));
  }

  events.sort((a, b) => b.date.compareTo(a.date));
  return events;
}

/// Backed by the real `DataProvider` (same bridge pattern as
/// `ProviderDashboardRepository`). Every list below lives on `DataProvider`
/// already (seeded from `mock_clients.dart` for now) — this class just
/// filters each one down to a single client's records, newest first where
/// a date exists.
class ProviderClientRepository implements ClientRepository {
  final DataProvider dataProvider;

  const ProviderClientRepository(this.dataProvider);

  @override
  Future<List<Client>> fetchClients() async =>
      List.unmodifiable(dataProvider.clients);

  @override
  Future<Client?> fetchClient(String clientId) async {
    for (final client in dataProvider.clients) {
      if (client.id == clientId) return client;
    }
    return null;
  }

  @override
  Future<List<Appointment>> fetchAppointments(String clientId) async {
    final list = dataProvider.appointments
        .where((a) => a.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<EyeExam>> fetchEyeExams(String clientId) async {
    final list = dataProvider.eyeExams
        .where((e) => e.clientId == clientId)
        .toList()
      ..sort((a, b) => b.examDate.compareTo(a.examDate));
    return list;
  }

  @override
  Future<List<Invoice>> fetchInvoices(String clientId) async {
    final list = dataProvider.invoices
        .where((i) => i.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<Payment>> fetchPayments(String clientId) async {
    // Payment only carries `invoiceId`, not `clientId` — join through this
    // client's invoices first.
    final invoiceIds = dataProvider.invoices
        .where((i) => i.clientId == clientId)
        .map((i) => i.id)
        .toSet();
    final list =
        dataProvider.payments
            .where((p) => invoiceIds.contains(p.invoiceId))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<Insurance>> fetchInsurances(String clientId) async {
    return dataProvider.insurances.where((i) => i.clientId == clientId).toList();
  }

  @override
  Future<List<DocumentRecord>> fetchDocuments(String clientId) async {
    final list = dataProvider.documents
        .where((d) => d.clientId == clientId)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  @override
  Future<List<DigitalSignature>> fetchSignatures(String clientId) async {
    final list = dataProvider.signatures
        .where((s) => s.clientId == clientId)
        .toList()
      ..sort((a, b) => b.signedAt.compareTo(a.signedAt));
    return list;
  }

  @override
  Future<ClientMetrics> fetchClientMetrics(String clientId) async =>
      deriveClientMetrics(dataProvider, clientId);

  @override
  Future<List<Prescription>> fetchPrescriptions(String clientId) async {
    final list = dataProvider.prescriptions
        .where((p) => p.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<Measurement>> fetchMeasurements(String clientId) async {
    final list = dataProvider.measurements
        .where((m) => m.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<ContactLensPrescription>> fetchContactLensPrescriptions(
    String clientId,
  ) async {
    final list = dataProvider.contactLensPrescriptions
        .where((c) => c.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<ClientTimelineEvent>> fetchClientTimeline(
    String clientId,
  ) async =>
      deriveClientTimeline(dataProvider, clientId);
}
